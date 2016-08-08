// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include <xscope.h>
#include "a_series_adc.h"
#include "pwm_tutorial_example.h"
#include "debug_print.h"

#define PWM_PERIOD           200 // Set PWM period to 2us, 500KHz
#define ADC_PERIOD        100000 // 1ms ADC trigger - Sample at 1KHz
#define PRINT_PERIOD    10000000 // 100ms printing rate


#define pwm_duty_calc(x) ((x * (PWM_PERIOD-2)) >> 8) //duty calc macro, 255 input = full scale

//Port definitions
//Note that these assume use of XP-SKC-A16 + XA-SK-MIXED-SIGNAL hardware
on tile[0]: port trigger_port = PORT_ADC_TRIGGER; //XD70 Port P32A bit 19
on tile[0]: port pwm_dac_port = XS1_PORT_1G;      //XD22 PWM2 on mixed signal slice

void xscope_user_init(void) {
   xscope_register(2,
           XSCOPE_CONTINUOUS, "Joystick ADC2", XSCOPE_UINT, "8b value",
           XSCOPE_CONTINUOUS, "Header ADC4", XSCOPE_UINT, "8b value");
   xscope_config_io(XSCOPE_IO_BASIC);
}

void adc_pwm_dac_example(chanend c_adc, chanend c_pwm_dac)
{
    timer        t_adc_timer, t_print_timer;
    unsigned int adc_time, print_time;
    unsigned data[2]; //Array for storing ADC results

    unsigned char joystick, header, header_old; //ADC values

    debug_printf("Analog loopback demo started.\n");

    at_adc_config_t adc_config = {{ 0, 0, 0, 0, 0, 0, 0, 0 }, 0, 0, 0 }; //initialise all ADC to off
    adc_config.input_enable[2] = 1; //Input 2 is horizontal axis of the joystick
    adc_config.input_enable[4] = 1; //Input 4 is ADC4 analog input on header
    adc_config.bits_per_sample = ADC_8_BPS;
    adc_config.samples_per_packet = 2; //Allow both samples to be sent in one hit
    adc_config.calibration_mode = 0; //Normal ADC operation - disable self calibration

    at_adc_enable(analog_tile, c_adc, trigger_port, adc_config);

    c_pwm_dac <: PWM_PERIOD;         //Set PWM period
    c_pwm_dac <: pwm_duty_calc(0);   //Set initial duty cycle

    t_print_timer :> print_time;     //Set print timer for first loop tick
    print_time += PRINT_PERIOD;

    t_adc_timer :> adc_time;         //Set ADC timer for first loop tick
    adc_time += ADC_PERIOD;

    at_adc_trigger_packet(trigger_port, adc_config); //Fire the ADC!

    while (1)
    {
        //Main loop. CPU will wait until one of these events occurs, then service it
    	select
        {
            case t_print_timer when timerafter(print_time) :> void:
                if (header != header_old){ //only do if value on header input has changed
                    debug_printf("ADC joystick : %u\t", joystick);
                    debug_printf("ADC header : %u\r", header);
                    header_old = header;
                }
                print_time += PRINT_PERIOD;//Setup time for next print event
                break;

            case t_adc_timer when timerafter(adc_time) :> void:
                c_pwm_dac <: pwm_duty_calc((unsigned int)joystick); //send joystick value to to PWM
                at_adc_trigger_packet(trigger_port, adc_config);    //Trigger ADC
                xscope_int(0, joystick);                     //send data to xscope
                xscope_int(1, header);                       //send data to xscope
                adc_time += ADC_PERIOD;                             //Setup time for next ADC rx event
                break;

            case at_adc_read_packet(c_adc, adc_config, data): //if data ready to be read from ADC
                joystick = (unsigned char) data[0]; //First value in packet
                header = (unsigned char) data[1];   //Second value in packet
                break;
        }
    }
}

int main()
{
    chan c_adc, c_pwm_dac;

    par { //two logical cores and ADC service hardware on channel ends
        on tile[0]: adc_pwm_dac_example(c_adc, c_pwm_dac);
        on tile[0]: pwm_tutorial_example ( c_pwm_dac, pwm_dac_port, 1);
        xs1_a_adc_service(c_adc);
    }
    return 0;
}

