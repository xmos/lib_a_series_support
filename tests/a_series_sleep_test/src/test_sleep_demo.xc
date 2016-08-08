// Copyright (c) 2015-2016, XMOS Ltd, All rights reserved
#include "debug_conf.h"
#include "a_series_sleep.h"
#include "debug_print.h"
#include <platform.h>
#include <xscope.h>

#define RTC_TIME 1000  //Time awake in ms
#define SLEEP_TIME 10000  //Time asleep in ms

on tile[0] : port leds = XS1_PORT_4E;

//function to initialise the sleep memory test array
void init_sleep_mem(char write_val, char memory[], unsigned char size ){
  for (unsigned i = 0; i < size; i++)
    memory[i] = write_val;
}

int compare_sleep_mem(char memory_w[], char memory_r[], unsigned char size ){
  int are_different = 0;
  for (unsigned i = 0; i < size; i++) if (memory_w[i] != memory_r[i]) are_different = 1;
  return are_different;
}

void sleep_demo(void){

  // Writes an led (using the gpio slice plugged into tile[0], triangle) 
  // for a few seconds. This allows us to tell that the 
  // xcore wakes up from sleep mode, as it will do this first.
  // Note: This executable need to be loaded into the flash so as 
  // it can rerun this binary on reset (i.e. after waking up).
  for (unsigned int i = 0; i < 5; ++i) {
    leds <: 0;
    delay_seconds(1);
    leds <: 0xf;
    delay_seconds(1);
  }

  timer tmr;
  int sys_start_time, temp, all_tests_passed = 1;
  unsigned int rtc_start_time, rtc_end_time, alarm_time;

  //Declare memory arrays/structures to test sleep memory read/write. Deliberately, they are a different type
  //than the sleep memory. It is expected that structures for example, may be stored
  int sleep_mem_to_write[XS1_SU_NUM_GLX_PER_MEMORY_BYTE/4], sleep_mem_read[XS1_SU_NUM_GLX_PER_MEMORY_BYTE/4];

  //initialise sleep memory shadow. Two buffers - one gets written and the other is what's read back
  init_sleep_mem(0xed, (sleep_mem_to_write, char[]), sizeof(sleep_mem_to_write));
  init_sleep_mem(0x00, (sleep_mem_read, char[]), sizeof(sleep_mem_read));

  debug_printf("Sleep function test application started\n");

  if (!at_pm_memory_is_valid()) debug_printf("PASS: Deep sleep memory not yet validated after reset\n");
  else {
    debug_printf("FAIL: Deep sleep memory incorrectly reports being valid\n",temp);
    all_tests_passed = 0;
  }
  at_pm_memory_validate(); //Set deep sleep memory status to valid

  if (at_pm_memory_is_valid()) debug_printf("PASS: Deep sleep memory correctly set to valid\n");
  else {
    debug_printf("FAIL: Deep sleep incorrectly reports being invalid\n",temp);
    all_tests_passed = 0;
  }

  //Write the sleep memory and read it back
  at_pm_memory_write(sleep_mem_to_write);
  at_pm_memory_read(sleep_mem_read);

  if (!compare_sleep_mem((sleep_mem_to_write, char[]), (sleep_mem_read, char[]), sizeof(sleep_mem_to_write)))
          debug_printf("PASS: Successfully wrote and read back sleep memory\n");
  else {
      debug_printf("FAIL: Sleep memory written/read back contents different\n");
      all_tests_passed = 0;
  }

  //Try out the RTC reset and read functions
  at_rtc_reset();
  temp = at_rtc_read();
  if (!temp) debug_printf("PASS: RTC reset to zero successfully\n");
  else {
    debug_printf("FAIL: RTC should read zero, but instead reads 0x%x\n",temp);
    all_tests_passed = 0;
  }

  tmr :> sys_start_time; //get current time (xcore timer)
  rtc_start_time =  at_rtc_read();//read rtc time

  tmr when timerafter(sys_start_time + (RTC_TIME * 100000)) :> void;
  rtc_end_time = at_rtc_read();
  if (rtc_end_time-rtc_start_time == RTC_TIME) debug_printf("PASS: RTC timer in synch with xcore timer over %dms\n", RTC_TIME);
  else {
    debug_printf("FAIL: RTC should have increemented by %d, but instead incremented by %d\n",
            RTC_TIME, rtc_end_time-rtc_start_time);
    all_tests_passed = 0;
  }

  if (all_tests_passed) debug_printf("PASS: All automated tests passed\n");
  else debug_printf("FAIL: One or more automated tests failed\n");

  //The following code cannot be automated due to the chip powering down and debugger disconnecting
  at_pm_set_min_sleep_time(150);            //Set min sleep period to about 150ms.
  alarm_time = at_rtc_read() + SLEEP_TIME;  //Calculate wakeup time
  at_pm_set_wake_time(alarm_time);          //set alarm time (wakeup)
  at_pm_enable_wake_source(RTC);            //Enable RTC wakeup
  at_pm_enable_wake_source(WAKE_PIN_LOW);   //Enable Wake pin = low wakeup

  debug_printf("Going to sleep now for %u ms, alarm time = %ums\n", SLEEP_TIME, alarm_time);
  debug_printf("Sleep test PASS if sleep is observed for about %ds, or until WAKE pin goes high (Tile 0, XD43)\n", SLEEP_TIME/1000);
  debug_printf("Hint: Measure voltage between pins 1 and 3 on XTAG analog connctor H to observe chip current\n");

  at_pm_sleep_now(); //Go to sleep. Debugger will disconnect after this due to chip being powered down

  // Note: If this binary is in the flash, then when it wakes up (resets) it will 
  // rerun, the leds will flash, which will signify that this test has passed.
}


int main (void)
{
  par{
      on tile[0]: sleep_demo();
  }
  return 0;
}


