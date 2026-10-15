/* Sort up to ten bounded values and encode quartile statistics. */
#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t quartile(const int64_t *input, size_t length,
                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 11) return -1;
    const int64_t count_value = input[0];
    if (count_value < 1 || count_value > 10 || length != (size_t)count_value + 1) return -1;
    int64_t values[10];
    for (size_t i = 0; i < (size_t)count_value; ++i) {
        if (input[i + 1] < 0 || input[i + 1] > 99) return -1;
        values[i] = input[i + 1];
    }
    const size_t count = (size_t)count_value;
    for (size_t i = 0; i < count; ++i) {
        for (size_t j = 0; j < count; ++j) {
            if (values[i] < values[j]) {
                const int64_t temporary = values[i]; values[i] = values[j]; values[j] = temporary;
            }
        }
    }
    const int64_t q1 = values[count / 4];
    const int64_t q3 = values[(3 * count) / 4];
    const size_t required = (count + 4) * 8;
    if (output == NULL || output_capacity < required) return -2;
    store_i64_le(output, 0, count_value);
    for (size_t i = 0; i < count; ++i) store_i64_le(output, 8 * (i + 1), values[i]);
    store_i64_le(output, 8 * (count + 1), q1);
    store_i64_le(output, 8 * (count + 2), q3);
    store_i64_le(output, 8 * (count + 3), q3 - q1);
    return (int64_t)required;
}
