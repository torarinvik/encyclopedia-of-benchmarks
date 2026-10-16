/* Generate leading decimal digits with the pinned spigot recurrence. */
#include <stddef.h>
#include <stdint.h>

#define MAX_DIGITS 256
#define MAX_BOXES 854

int64_t spigotpi(const int64_t *input, size_t length, uint8_t *output,
                 size_t output_capacity)
{
    if (length != 1 || input == NULL || input[0] < 0 || input[0] > MAX_DIGITS) return -1;
    const size_t digit_count = (size_t)input[0];
    if (output == NULL || output_capacity < digit_count) return -2;
    if (digit_count == 0) return 0;

    const size_t boxes = digit_count * 10 / 3;
    int64_t remainders[MAX_BOXES];
    for (size_t index = 0; index < boxes; ++index) remainders[index] = 2;
    size_t digits_held = 0;
    for (size_t index = 0; index < digit_count; ++index) {
        int64_t carried_over = 0, sum = 0;
        for (size_t cursor = boxes; cursor > 0; ) {
            const size_t j = --cursor;
            remainders[j] *= 10;
            sum = remainders[j] + carried_over;
            const int64_t quotient = sum / ((int64_t)j * 2 + 1);
            remainders[j] = sum % ((int64_t)j * 2 + 1);
            carried_over = quotient * (int64_t)j;
        }
        remainders[0] = sum % 10;
        int64_t q = sum / 10;
        if (q == 9) {
            ++digits_held;
        } else if (q == 10) {
            q = 0;
            for (size_t offset = 1; offset <= digits_held; ++offset) {
                const size_t position = index - offset;
                output[position] = output[position] == '9' ? '0' : (uint8_t)(output[position] + 1);
            }
            digits_held = 1;
        } else {
            digits_held = 1;
        }
        output[index] = (uint8_t)('0' + q);
    }
    return (int64_t)digit_count;
}
