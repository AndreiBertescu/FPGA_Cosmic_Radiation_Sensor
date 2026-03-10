#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ST7735.h>
#include <Adafruit_NeoPixel.h>
#include <Fonts/FreeMono9pt7b.h>

#define NUM_BYTES 10

#define LVDS_SS 2
#define BTN_PIN 18
#define LED_PIN 8

#define LCD_SS 11
#define LCD_DC 12
#define LCD_RES 13


typedef struct {
  uint8_t status;
  uint16_t scan_number;

  uint16_t bram_index;
  uint8_t bram_index_checksum;

  uint16_t bram_address;
  uint8_t bram_address_checksum;

  uint32_t bitmap;
} AICORS_Data;

SPISettings spiSettings(1000000, MSBFIRST, SPI_MODE0);
Adafruit_ST7735 tft = Adafruit_ST7735(LCD_SS, LCD_DC, LCD_RES);
Adafruit_NeoPixel strip(1, 0, NEO_GRB + NEO_KHZ800);
AICORS_Data aicors;
int counter = 0;


void setup() {
  // Init pins
  pinMode(BTN_PIN, INPUT);
  pinMode(LVDS_SS, OUTPUT);
  digitalWrite(LVDS_SS, HIGH);

  // Init comms
  SPI.begin();
  Serial.begin(115200);
  Serial.println("SPI Master Initialized");

  // Init lcd
  tft.initR(INITR_GREENTAB);
  tft.setRotation(1);
  tft.setFont(&FreeMono9pt7b);
  tft.fillScreen(ST77XX_BLACK);

  tft.setCursor(10, 60);
  tft.print("Press button");
  tft.setCursor(10, 80);
  tft.print("  for scan");

  // Init rgb LED
  strip.setPin(LED_PIN);
  strip.begin();
  strip.setPixelColor(0, strip.Color(0, 0, 10));
  strip.show();
}

void loop() {
  if (!digitalRead(BTN_PIN)) {
    spi_transaction(&aicors);
    handleScreen(&aicors);

    strip.setPixelColor(0, strip.Color(50, 0, 50));
    strip.show();
    delay(125);
    strip.setPixelColor(0, strip.Color(0, 0, 10));
    strip.show();
    delay(125);
  }
}

/////////////// Handles reading from AICORS board
void spi_transaction(AICORS_Data *d) {
  uint8_t received[NUM_BYTES] = { 0 };

  SPI.beginTransaction(spiSettings);
  digitalWrite(LVDS_SS, LOW);

  for (int i = 0; i < NUM_BYTES; i++) {
    received[i] = SPI.transfer(0x20 + i);
  }

  digitalWrite(LVDS_SS, HIGH);
  SPI.endTransaction();

  // Parse payload
  d->status = received[0];

  d->scan_number = (received[1] << 8) | received[2];

  d->bram_index = ((received[3] & 0b00000011) << 8) | received[4];
  d->bram_index_checksum = (received[3] & 0b01111100) >> 2;

  d->bram_address = ((received[5] & 0b00001111) << 8) | received[6];
  d->bram_address_checksum = (received[5] & 0b11110000) >> 4;

  d->bitmap = ((uint32_t)received[7] << 16) | ((uint32_t)received[8] << 8) | received[9];

  // Debug print
  Serial.print("Received #");
  Serial.println(counter++);

  Serial.print("Status register: ");
  for (int i = 7; i >= 0; i--)
    Serial.print((d->status >> i) & 1);
  Serial.println();

  Serial.print("Scan Number    : ");
  Serial.println(d->scan_number);

  Serial.print("BRAM index     : ");
  Serial.print(d->bram_index);
  Serial.print(" CRC: ");
  Serial.println(d->bram_index_checksum, BIN);

  Serial.print("BRAM address   : ");
  Serial.print(d->bram_address);
  Serial.print(" CRC: ");
  Serial.println(d->bram_address_checksum, BIN);

  Serial.print("Bitmap         : ");
  for (int i = 17; i >= 0; i--)
    Serial.print((d->bitmap >> i) & 1);
  Serial.println("\n");
}

/////////////// Handles screen output
void handleScreen(const AICORS_Data *d) {
  char buf[64];
  tft.fillScreen(ST77XX_BLACK);

  int y = 20;
  int line = 20;

  // Status bits
  char status_str[9];
  for (int i = 7; i >= 0; i--)
    status_str[7 - i] = ((d->status >> i) & 1) ? '1' : '0';
  status_str[8] = '\0';

  tft.setCursor(5, y);
  snprintf(buf, sizeof(buf), "Sts : %s", status_str);
  tft.print(buf);
  y += line;

  tft.setCursor(5, y);
  snprintf(buf, sizeof(buf), "Scan no.:%d", d->scan_number);
  tft.print(buf);
  y += line;

  tft.setCursor(5, y);
  snprintf(buf, sizeof(buf), "BRAM id :%d", d->bram_index);
  tft.print(buf);
  y += line;

  tft.setCursor(5, y);
  snprintf(buf, sizeof(buf), "BRAM adr:%d", d->bram_address);
  tft.print(buf);
  y += line;

  tft.setCursor(5, y);
  tft.print("Error bitmap:");
  y += line;

  // Bitmap (18 bits)
  char bitmap_str[19];
  for (int i = 17; i >= 0; i--)
    bitmap_str[17 - i] = ((d->bitmap >> i) & 1) ? '1' : '0';
  bitmap_str[18] = '\0';

  tft.setCursor(5, y);
  tft.print(bitmap_str);
  y += line;
}
