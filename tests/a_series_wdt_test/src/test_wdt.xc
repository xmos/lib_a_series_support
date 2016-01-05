// Copyright (c) 2016, XMOS Ltd, All rights reserved
#include "debug_conf.h"
#include "debug_print.h"
#include "a_series_wdt.h"

#define WATCHDOG_PERIOD 500//ms

int main (void)
{
  timer tmr;
  int start_time, end_time;

  debug_printf("WDT test started, using %d milliseconds overflow period.\n", WATCHDOG_PERIOD);
  debug_printf("If this is the last messsage you see, the test has FAILED.\n");

  at_watchdog_set_timeout(WATCHDOG_PERIOD);   //Set timeout period
  at_watchdog_enable();                       //Switch on WDT
  tmr :> start_time;
  end_time = start_time + (WATCHDOG_PERIOD - 1) * 100000; //Wait until just before WDT overflow
  at_watchdog_kick();
  tmr when timerafter (end_time) :> void;

  at_watchdog_kick();
  debug_printf("PASS: Enabled WDT did not kick in after %d milliseconds.\n", ((end_time - start_time)/100000));

  at_watchdog_disable();
  debug_printf("If this is the last messsage you see, the test has FAILED.\n");
  tmr :> start_time;
  end_time = start_time + (WATCHDOG_PERIOD + 1) * 100000; //Wait until just before WDT overflow
  at_watchdog_kick();
  tmr when timerafter (end_time) :> void;
  debug_printf("PASS: Disabled WDT did not kick in at %d milliseconds.\n", ((end_time - start_time)/100000));

  at_watchdog_enable();
  debug_printf("If this is the last messsage you see, the test has PASSED because the watchdog reset the chip OK.\n");
  tmr :> start_time;
  end_time = start_time + (WATCHDOG_PERIOD + 1) * 100000; //Wait until just before WDT overflow
  at_watchdog_kick();
  tmr when timerafter (end_time) :> void;

  debug_printf("FAIL: WDT did not kick in at %d milliseconds.\n", ((end_time - start_time)/100000));
  return 0;
}

