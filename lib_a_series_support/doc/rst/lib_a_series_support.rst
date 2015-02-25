.. include:: ../../../README.rst

A-Series ADC API
----------------

.. doxygenenum:: at_adc_bits_per_sample_t
.. doxygenstruct:: at_adc_config_t
.. doxygenfunction:: at_adc_enable
.. doxygenfunction:: at_adc_disable_all
.. doxygenfunction:: at_adc_trigger
.. doxygenfunction:: at_adc_trigger_packet
.. doxygenfunction:: at_adc_read
.. doxygenfunction:: at_adc_read_packet

A-Series Sleep API
------------------

.. doxygenenum:: at_wake_sources_t
.. doxygendefine:: at_pm_memory_read
.. doxygendefine:: at_pm_memory_write
.. doxygenfunction:: at_pm_memory_is_valid
.. doxygenfunction:: at_pm_memory_validate
.. doxygenfunction:: at_pm_memory_invalidate
.. doxygenfunction:: at_pm_enable_wake_source
.. doxygenfunction:: at_pm_set_wake_time
.. doxygenfunction:: at_pm_set_min_sleep_time
.. doxygenfunction:: at_pm_sleep_now
.. doxygenfunction:: at_rtc_read
.. doxygenfunction:: at_rtc_reset

A-Series Watchdog-Timer API
---------------------------

.. doxygenfunction:: at_watchdog_enable
.. doxygenfunction:: at_watchdog_disable
.. doxygenfunction:: at_watchdog_set_timeout
.. doxygenfunction:: at_watchdog_kick

