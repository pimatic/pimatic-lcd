module.exports = {
  title: "lcd plugin config options"
  type: "object"
  properties:
    bus:
      description: "i2c bus device"
      type: "string"
      default: "/dev/i2c-1"
    address:
      description: "address of the device"
      type: "string"
      default: "0x27"
    rows:
      description: "number of rows (lines) of the LCD"
      type: "number"
      default: 4
    cols: 
      description: "number of cols (characters in a line) of the LCD"
      type: "number"
      default: 20
}