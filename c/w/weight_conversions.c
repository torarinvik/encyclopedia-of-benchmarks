/* Preserve the six integer weight-conversion strings from the pinned Ruby source. */
#include <stddef.h>
#include <stdint.h>

#define MAX_AMOUNT 1000000
#define OUTPUT_SIZE 64

static size_t append_text(uint8_t *buffer, size_t position, const char *text) {
    while (*text != '\0') buffer[position++] = (uint8_t)*text++;
    return position;
}

static size_t append_i64(uint8_t *buffer, size_t position, int64_t value) {
    uint8_t digits[24];
    size_t count = 0;
    uint64_t magnitude;
    if (value < 0) {
        buffer[position++] = '-';
        magnitude = (uint64_t)(-(value + 1)) + 1;
    } else {
        magnitude = (uint64_t)value;
    }
    do {
        digits[count++] = (uint8_t)('0' + magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    while (count != 0) buffer[position++] = digits[--count];
    return position;
}

static size_t append_fixed(uint8_t *buffer, size_t position, double value) {
    const double scaled = value * 100.0;
    int64_t cents = value < 0.0
        ? -(int64_t)(-scaled + 0.5)
        : (int64_t)(scaled + 0.5);
    if (value > 0.0 && ((double)cents + 0.5) / 100.0 <= value) ++cents;
    else if (value < 0.0 && ((double)cents - 0.5) / 100.0 >= value) --cents;
    if (cents < 0) {
        buffer[position++] = '-';
        cents = -cents;
    }
    position = append_i64(buffer, position, cents / 100);
    const int64_t fraction = cents % 100;
    buffer[position++] = '.';
    if (fraction == 0) {
        buffer[position++] = '0';
    } else if (fraction % 10 == 0) {
        buffer[position++] = (uint8_t)('0' + fraction / 10);
    } else {
        buffer[position++] = (uint8_t)('0' + fraction / 10);
        buffer[position++] = (uint8_t)('0' + fraction % 10);
    }
    return position;
}

int64_t weight_conversions(const int64_t *input, size_t length,
                           uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 2 || input[0] < 0 || input[0] > 5 ||
        input[1] < -MAX_AMOUNT || input[1] > MAX_AMOUNT) return -1;

    const int64_t operation = input[0];
    const int64_t amount = input[1];
    uint8_t buffer[OUTPUT_SIZE];
    size_t position = 0;
    int64_t converted = 0;
    if (operation == 0) {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " kg = ");
        position = append_i64(buffer, position, amount * 1000);
        position = append_text(buffer, position, " g");
    } else if (operation == 1) {
        converted = amount >= 0 ? amount / 1000 : -((-amount + 999) / 1000);
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " g = ");
        position = append_i64(buffer, position, converted);
        position = append_text(buffer, position, " kg");
    } else if (operation == 2) {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " lb = ");
        position = append_i64(buffer, position, amount * 16);
        position = append_text(buffer, position, " oz");
    } else if (operation == 3) {
        converted = amount >= 0 ? amount / 16 : -((-amount + 15) / 16);
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " oz = ");
        position = append_i64(buffer, position, converted);
        position = append_text(buffer, position, " lb");
    } else if (operation == 4) {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " kg = ");
        position = append_fixed(buffer, position, (double)amount * 2.205);
        position = append_text(buffer, position, " lb");
    } else {
        position = append_i64(buffer, position, amount);
        position = append_text(buffer, position, " lb = ");
        position = append_fixed(buffer, position, (double)amount / 2.205);
        position = append_text(buffer, position, " kg");
    }

    buffer[position] = 0;
    if (output_capacity < position + 1 || output == NULL) return -2;
    for (size_t index = 0; index <= position; ++index) output[index] = buffer[index];
    return (int64_t)position;
}
