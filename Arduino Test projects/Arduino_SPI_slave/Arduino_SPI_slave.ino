#include <SPI.h>

const int SS_PIN = 2;
const int NUM_BYTES = 10;

SPISettings spiSettings(1000000, MSBFIRST, SPI_MODE0);

void setup() {
  pinMode(SS_PIN, OUTPUT);
  digitalWrite(SS_PIN, HIGH);

  SPI.begin();
  Serial.begin(115200);
  Serial.println("SPI Master Initialized");
}

void loop() {
  static unsigned long lastReadTime = 0;
  unsigned long currentMillis = millis();

  if (currentMillis - lastReadTime >= 5) {
    lastReadTime = currentMillis;

    uint8_t received[NUM_BYTES] = {0};
    uint8_t golden[8] = {0x91, 0x11, 0x11, 0x1A, 0xA1, 0x11, 0x11, 0x19};

    SPI.beginTransaction(spiSettings);
    digitalWrite(SS_PIN, LOW);  // Select slave
    // delayMicroseconds(1);       // Allow slave to prepare

    // Read NUM_BYTES from slave
    for (int i = 0; i < NUM_BYTES; i++) {
      received[i] = SPI.transfer(0x20 + i);  // Send dummy byte, receive real byte
    }

    digitalWrite(SS_PIN, HIGH);
    SPI.endTransaction();

    // Print received bytes
    Serial.print("Received: ");
    for (int i = 0; i < NUM_BYTES; i++) {
      // Serial.print("0x");
      if (received[i] < 0x10) Serial.print("0");
      Serial.print(received[i], HEX);
      Serial.print(" ");
    }

    // for (int i = 0; i < NUM_BYTES; i++) {
    //   if (received[i] != golden[i]) {
    //     Serial.print("error!");
    //     break;
    //   }
    // }

    Serial.println();
  }
}
