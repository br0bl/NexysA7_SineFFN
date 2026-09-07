HardwareSerial NexysA7_UART(2);

const float INPUT_SCALE = 0.024480115622282028f;
const int INPUT_ZERO_POINT = -128;

const float OUTPUT_SCALE = 0.008290956728160381f;
const int OUTPUT_ZERO_POINT = 5;

bool waiting_for_response = false;

void setup()
{
    Serial.begin(115200);
    NexysA7_UART.begin(115200, SERIAL_8N1, 25, 26);

    Serial.println("Enter an angle in degrees:");
}

void loop()
{
    if(Serial.available() && !waiting_for_response)
    {
        String input = Serial.readStringUntil('\n');
        input.trim();

        char *end_pointer;
        float degrees = strtof(input.c_str(), &end_pointer);

        if(end_pointer != input.c_str() && *end_pointer == '\0')
        {
            degrees = fmodf(degrees, 360.0f);
            if(degrees < 0.0f) degrees += 360.0f;

            float radians = degrees * PI / 180.0f;
            long quantized = lroundf(radians / INPUT_SCALE) + INPUT_ZERO_POINT;

            if(quantized < -128) quantized = -128;
            if(quantized > 127) quantized = 127;

            int8_t x_q = (int8_t)quantized;
            NexysA7_UART.write((uint8_t)x_q);
            waiting_for_response = true;

            Serial.print("Degrees: ");
            Serial.println(degrees, 3);
            Serial.print("Sent x_q: ");
            Serial.println((int)x_q);
        }
        else
        {
            Serial.println("Invalid input.");
            Serial.println("Enter an angle in degrees:");
        }
    }

    if(NexysA7_UART.available() && waiting_for_response)
    {
        uint8_t received = NexysA7_UART.read();
        int8_t y_q = (int8_t)received;
        float sine_approximation = OUTPUT_SCALE * ((int)y_q - OUTPUT_ZERO_POINT);

        Serial.print("Received y_q: ");
        Serial.println((int)y_q);
        Serial.print("Approximate sine: ");
        Serial.println(sine_approximation, 6);
        Serial.println();
        Serial.println("Enter an angle in degrees:");

        waiting_for_response = false;
    }
}
