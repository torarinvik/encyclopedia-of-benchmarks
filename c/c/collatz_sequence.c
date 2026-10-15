#include <stddef.h>
#include <stdint.h>

#define MAX_START 1000000

static int64_t next_term(int64_t value)
{
    return value % 2 == 0 ? value / 2 : 3 * value + 1;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t collatz_sequence(const int64_t *input, size_t length,
                         uint8_t *output, size_t output_capacity)
{
    if (length != 1 || input[0] < 1 || input[0] > MAX_START) return -1;
    int64_t current = input[0];
    size_t term_count = 1;
    while (current != 1) {
        current = next_term(current);
        ++term_count;
    }
    const size_t required = term_count * 8;
    if (output_capacity < required || (required != 0 && output == NULL)) return -2;
    current = input[0];
    size_t written = 0;
    for (;;) {
        store_i64_le(output, written, current);
        written += 8;
        if (current == 1) break;
        current = next_term(current);
    }
    return (int64_t)written;
}
