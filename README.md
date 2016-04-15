pimatic-lcd
===========

pimatic support for LCD Displays using i2c serial bus.

Tested with:
* 2004 LCD Display Module HD44780 (20x4)
* 1602 LCD Display Module HD44780 (16x2)

Example config:
--------------

```json
{
  "plugin": "lcd",
  "bus": "/dev/i2c-1",
  "rows": 4,
  "cols": 20
}
```

If the i2c address of the LCD Display Module is different from the default address `0x27`, the `address` property 
needs to be set. If the address of the module is unknown the `i2cdetect` tool can be used which is part 
of the `i2c-tools` package on Raspbian. 
Note, the addresses output by the tool are hexadecimal numbers. To set the address property of the plugin 
accordingly, the number has to be provided as a string preceded by '0x'.

```json
{
  "plugin": "lcd",
  "bus": "/dev/i2c-1",
  "address": "0x23"
  "rows": 4,
  "cols": 20
}
```


Example rules:
--------------

```
IF $syssensor.cpu changes
THEN display "CPU: {$syssensor.cpu}%" on lcd line 1


IF $syssensor.cpu changes or $syssensor.memory changes
THEN display "CPU: {$syssensor.cpu}%" on lcd line 1 and display "MEM: {$syssensor.memory}MB" on lcd line 2


IF switch is turned off
THEN turn LCD backlight off


IF switch is turned off
THEN display "Bye bye" on lcd and after 5 seconds turn LCD backlight off
```