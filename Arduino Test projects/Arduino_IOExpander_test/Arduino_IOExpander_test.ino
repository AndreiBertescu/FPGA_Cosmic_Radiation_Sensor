#include <Wire.h>

const int I2C_ADDRESS = 0b0100000;

// IO pins:
// bit 0 - 2V5_VOLTAGE_EN
// bit 1 - 3V3_VOLTAGE_EN
// bit 2 - 1V8_VOLTAGE_EN
// bit 3 - 3V3_PWRGD
// bit 4 - FPAG_DONE
// bit 5 - FPGA_PROGB
// bit 6 - FPGA_INIT
// bit 7 - I2C_RESET

void setup() {
  Wire.begin();
  Wire.setClock(100000);
  Serial.begin(9600);
  Serial.println();

  // reset the FPGA
  write_two_register(I2C_ADDRESS, 0x01, 0b00000000);  //output reg
  write_two_register(I2C_ADDRESS, 0x03, 0b11011111);  //direction reg
  delay(10);

  // read signals and set all pins to input
  write_one_register(I2C_ADDRESS, 0x00);
  print_binary((int)read_8bit_register(I2C_ADDRESS), 8);
  write_two_register(I2C_ADDRESS, 0x03, 0b11111111);  //direction reg

  // // set direction reg
  // write_two_register(I2C_ADDRESS, 0x01, 0b10000000);  //output reg
  // write_two_register(I2C_ADDRESS, 0x03, 0b01111111);  //direction reg
  // delay(10);

  // // read direction reg and reset the IO expander
  // print_binary((int)read_8bit_register(I2C_ADDRESS), 8);
  // Serial.println();
  // write_two_register(I2C_ADDRESS, 0x01, 0b01111111);  //direction reg
} 

void loop() {  
  // read input reg
  write_one_register(I2C_ADDRESS, 0x00);
  print_binary((int)read_8bit_register(I2C_ADDRESS), 8);
  Serial.print(" --- ");

  // read direction reg
  write_one_register(I2C_ADDRESS, 0x03);
  print_binary((int)read_8bit_register(I2C_ADDRESS), 8);

  Serial.println();
  delay(500);
}

uint8_t read_8bit_register(uint8_t i2c_address)
{
  uint8_t value = 0;
  
  Wire.requestFrom((int)i2c_address, (int)1);
  while (Wire.available())
    value = Wire.read(); 
  
  return value;
}

void write_two_register(uint8_t i2c_address, uint8_t reg_address, uint8_t reg_data){
  Wire.beginTransmission(i2c_address);
  Wire.write(reg_address);
  Wire.write(reg_data);
  handleI2CError(Wire.endTransmission());
}

void write_one_register(uint8_t i2c_address, uint8_t reg_address)
{
  Wire.beginTransmission(i2c_address);
  Wire.write(reg_address);
  handleI2CError(Wire.endTransmission());
}

void handleI2CError(int errorCode) {
    switch (errorCode) {
        case 0:
            break;
        case 1:
            Serial.println("\nError: Data too long to fit in transmit buffer.\n");
            break;
        case 2:
            //Serial.println("\nError: Received NACK on transmit of address.\n");
            break;
        case 3:
            Serial.println("\nError: Received NACK on transmit of data.\n");
            break;
        case 4:
            Serial.println("\nError: Other error.\n");
            break;
        case 5:
            Serial.println("\nError: Timeout.\n");
            break;
        default:
            Serial.println("\nError: Unknown error code.\n");
            break;
    }
}

void print_binary(int value, uint8_t nr_of_bits) {
  for (int i = nr_of_bits - 1; i >= 0; i--) {

    Serial.print((value >> i) & 1);
    if (i % 4 == 0 && i != 0)
      Serial.print(" ");

  }
}
