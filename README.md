pimatic-lcd
===========

pimatic support for LCD Displays using i2c serial bus.

Tested with:
* 2004 LCD Display Module HD44780 (20x4)
* 1602 LCD Display Module HD44780 (16x2)

Exampe config:
--------------

```json
{
  "plugin": "lcd",
  "bus": "/dev/i2c-1"
  "rows": 4
  "cols": 20
}
```

Example rules:
--------------

```
IF $syssensor.cpu changes
THEN display "CPU: {$syssensor.cpu}%" on lcd line 1


IF $syssensor.cpu changes or $syssensor.memory changes
THEN display "CPU: {$syssensor.cpu}%" on lcd line 1 and display "MEM: {$syssensor.memor}MB" on lcd line 2


IF switch is turned off
THEN turn LCD backlight off


IF switch is turned off
THEN display "Bye bye" on lcd and after 5 seconds turn LCD backlight off
```