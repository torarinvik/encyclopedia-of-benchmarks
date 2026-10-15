/* Iterative extended Euclid for positive signed-32-bit inputs. */
#include <stddef.h>
#include <stdint.h>

static size_t store_i32(int64_t value, uint8_t *output, size_t position)
{
    uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) {
        output[position++] = (uint8_t)(bits & UINT32_C(255));
        bits >>= 8;
    }
    return position;
}

int64_t extended_euclidean_algorithm(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (length != 2 || input[0] < 1 || input[0] > INT32_MAX ||
        input[1] < 1 || input[1] > INT32_MAX) return -1;
    if (output_capacity < 12) return -2;

    int64_t old_r = input[0], remainder = input[1];
    int64_t old_x = 1, x = 0, old_y = 0, y = 1;
    while (remainder != 0) {
        const int64_t quotient = old_r / remainder;
        const int64_t next_r = old_r - quotient * remainder;
        old_r = remainder;
        remainder = next_r;
        const int64_t next_x = old_x - quotient * x;
        old_x = x;
        x = next_x;
        const int64_t next_y = old_y - quotient * y;
        old_y = y;
        y = next_y;
    }
    if (old_r > INT32_MAX || old_x < INT32_MIN || old_x > INT32_MAX ||
        old_y < INT32_MIN || old_y > INT32_MAX) return -1;
    size_t written = 0;
    written = store_i32(old_r, output, written);
    written = store_i32(old_x, output, written);
    written = store_i32(old_y, output, written);
    return written == 12 ? 3 : -1;
}
