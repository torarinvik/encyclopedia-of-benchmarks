/* Apply the bounded Java EMAFilter recurrence to an integer sample stream. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t ema_filter(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > 7) return -1;
    const int64_t alpha_units = input[0], count_value = input[1];
    if (alpha_units < 1 || alpha_units > 1024 || count_value < 0 || count_value > 4 ||
        length != 2 + (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count; ++index)
        if (input[index + 2] < -1000000 || input[index + 2] > 1000000) return -1;
    const size_t required = count * 8;
    if (output_capacity < required || (required > 0 && output == NULL)) return -2;

    const double alpha = (double)alpha_units / 1024.0;
    double ema_value = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const double sample = (double)input[index + 2];
        if (index == 0) ema_value = sample;
        else ema_value = alpha * sample + (1.0 - alpha) * ema_value;
        put_f64_le(output, index * 8, ema_value);
    }
    return (int64_t)required;
}
