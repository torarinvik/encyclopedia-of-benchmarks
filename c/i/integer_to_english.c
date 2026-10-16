#include <stddef.h>
#include <stdint.h>

static const char *SMALL[21] = {
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
    "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
    "Seventeen", "Eighteen", "Nineteen", "Twenty"
};
static const char *TENS[10] = {"", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"};
static const char *SCALES[4] = {"", "Thousand", "Million", "Billion"};

static size_t append_text(uint8_t *buffer, size_t position, const char *text) {
    while (*text != '\0') buffer[position++] = (uint8_t)*text++;
    return position;
}

static size_t append_word(uint8_t *buffer, size_t position, const char *text) {
    if (position != 0) buffer[position++] = ' ';
    return append_text(buffer, position, text);
}

static size_t append_group(uint8_t *buffer, size_t position, unsigned value) {
    if (value >= 100) {
        position = append_word(buffer, position, SMALL[value / 100]);
        position = append_word(buffer, position, "Hundred");
        value %= 100;
    }
    if (value <= 20) {
        if (value != 0) position = append_word(buffer, position, SMALL[value]);
    } else if (value % 10 == 0) {
        position = append_word(buffer, position, TENS[value / 10]);
    } else {
        position = append_word(buffer, position, TENS[value / 10]);
        position = append_word(buffer, position, SMALL[value % 10]);
    }
    return position;
}

int64_t integer_to_english(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length != 1 || input[0] < INT32_MIN || input[0] > INT32_MAX) return -1;
    const int64_t value = input[0];
    uint8_t buffer[128];
    size_t position = 0;
    if (value == 0) {
        position = append_word(buffer, position, "Zero");
    } else if (value > 0) {
        unsigned groups[4];
        size_t count = 0;
        uint32_t remaining = (uint32_t)value;
        while (remaining != 0) {
            groups[count++] = remaining % 1000;
            remaining /= 1000;
        }
        while (count > 0) {
            --count;
            if (groups[count] != 0) {
                position = append_group(buffer, position, groups[count]);
                if (count != 0) position = append_word(buffer, position, SCALES[count]);
            }
        }
    }
    if (position > output_capacity || (position != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < position; ++index) output[index] = buffer[index];
    return (int64_t)position;
}
