#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4096

static uint8_t lower_ascii(uint8_t value) { return value >= 'A' && value <= 'Z' ? (uint8_t)(value + 32) : value; }
static int is_vowel(uint8_t value) { return value == 'a' || value == 'e' || value == 'i' || value == 'o' || value == 'u'; }

int64_t remove_vowels(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_INPUT_LENGTH || length != 1 + (size_t)values[0]) return -1;
    const size_t text_length = (size_t)values[0];
    size_t result_length = 0;
    for (size_t i = 0; i < text_length; ++i) {
        if (values[i + 1] < 0 || values[i + 1] > 127) return -1;
        if (!is_vowel(lower_ascii((uint8_t)values[i + 1]))) ++result_length;
    }
    if (result_length > output_capacity || (result_length > 0 && output == NULL)) return -2;
    size_t written = 0;
    for (size_t i = 0; i < text_length; ++i) {
        uint8_t byte = lower_ascii((uint8_t)values[i + 1]);
        if (!is_vowel(byte)) output[written++] = byte;
    }
    return (int64_t)written;
}
