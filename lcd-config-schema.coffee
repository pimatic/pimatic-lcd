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
      type: "number"
      default: 0x27
}