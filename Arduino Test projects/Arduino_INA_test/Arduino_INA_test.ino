#include <Wire.h>

// Reads the 4 INA219 sensors through i2c and print the colected data

const int I2C_ADDRESS_2V5 = 0b1000011;
const int I2C_ADDRESS_3V3 = 0b1000010;
const int I2C_ADDRESS_1V8 = 0b1000001;
const int I2C_ADDRESS_1V  = 0b1000000;
const int I2C_ADDRESS_DUMMY = 0b1010101;

// The calibration register MUST be set for the INA to work. 
// FOR REV 2 - 55924 - R_Shunt = 0.003, Maximum current = 8A, so the conversion is easier
// FOR REV 3 - 22369 - R_Shunt = 0.02, Maximum current = 3A
<<<<<<< HEAD
const uint32_t calibration = 19000;
=======
const uint32_t calibration = 55924;
>>>>>>> 647cb9f9868c92c107b0d32821dc7a1e607e85ea

void setup() {
  Wire.begin();
  Wire.setClock(100000);
  Serial.begin(9600);

  // Initial configuration for every INA  
  // MUST be done at every power-on
  for(int i=0; i<4; i++){
    uint8_t i2c_address = 0b1000000 + i;

    write_two_register(i2c_address, 0x00, (1 << 15));           //reset

    write_two_register(i2c_address, 0x00, 0b0000011111111111);  //status
    write_two_register(i2c_address, 0x05, calibration);         //calibration
  }
} 

void loop() {  
  double total_power = 0;

  // Itterates through the sensors and collects the data 
  for(int i=0; i<4; i++){
    uint8_t i2c_address = 0b1000000 + i;

    Serial.println();
    Serial.print("Voltage: ");
    Serial.print(read_voltage(i2c_address), 3);

    Serial.print(" --- Shunt voltage[mV]: ");
    Serial.print(read_shunt_voltage(i2c_address), 3);

    Serial.print(" --- Current: ");
    int current = read_current(i2c_address);
    Serial.print(current);
    
    Serial.print(" --- Power: ");
    int power = read_power(i2c_address);
    Serial.print(power);

    double current_calc = (double)current / 4096;
    Serial.print(" --- Current[A]: ");
    Serial.print(current_calc, 3);

    double power_calc = (double)power * ((double)20/4096);
    Serial.print(" --- Power[W]: ");
    Serial.print(power_calc, 3);

    total_power += power_calc;
  }

  Serial.print("\nTotal power [W]: ");
  Serial.println(total_power, 3);

  delay(500);
}

double read_shunt_voltage(uint8_t i2c_address){
  write_one_register(i2c_address, 0x1);
  return (double)read_16bit_register(i2c_address) / 100;
}

double read_voltage(uint8_t i2c_address){
  write_one_register(i2c_address, 0x2);
  uint16_t value = read_16bit_register(i2c_address);

  // The first 3 bits are status bits
  // The register is 10bit
  // A lsb is 4mV
  return (double)(value >> 3) / 1000 * 4;
}

int read_power(uint8_t i2c_address){
  write_one_register(i2c_address, 0x3);
  return read_16bit_register(i2c_address);
}

int read_current(uint8_t i2c_address){
  write_one_register(i2c_address, 0x4);
  return read_16bit_register(i2c_address);
}

uint16_t read_16bit_register(uint8_t i2c_address)
{
  uint16_t value = 0;
  uint8_t c;
  
  Wire.requestFrom((int)i2c_address, (int)2);
  while (Wire.available()) { 
    c = Wire.read(); 
    value = (value << 8) + c;  
  }
  
  return value;
}

void write_two_register(uint8_t i2c_address, uint8_t reg_address, uint16_t reg_data){
  Wire.beginTransmission(i2c_address);
  Wire.write(reg_address);
  Wire.write(reg_data >> 8);
  Wire.write(reg_data);
  handleI2CError(Wire.endTransmission());
}

void write_one_register(int i2c_address, int reg_address)
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