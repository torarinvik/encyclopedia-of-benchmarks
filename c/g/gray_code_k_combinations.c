#include <stddef.h>
#include <stdint.h>

static size_t combination_count(unsigned n, unsigned k) {
    unsigned choose = k < n - k ? k : n - k;
    size_t count = 1;
    for (unsigned i = 1; i <= choose; ++i)
        count = count * (n - choose + i) / i;
    return count;
}

static void write_u16(uint8_t *output, size_t offset, uint16_t value) {
    output[offset] = (uint8_t)(value & 255u);
    output[offset + 1] = (uint8_t)(value >> 8);
}

int64_t gray_code_k_combinations(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length != 2 || input[0] < 0 || input[0] > 12 ||
        input[1] < 0 || input[1] > input[0]) return -1;
    const unsigned n = (unsigned)input[0], k = (unsigned)input[1];
    const size_t count = combination_count(n, k);
    const size_t required = 2 + 2 * count;
    if (output == NULL || capacity < required) return -2;
    write_u16(output, 0, (uint16_t)count);

    size_t emitted = 0;
    const uint32_t limit = UINT32_C(1) << n;
    for (uint32_t index = 0; index < limit; ++index) {
        const uint32_t mask = index ^ (index >> 1);
        uint32_t bits = mask;
        unsigned population = 0;
        while (bits != 0) { bits &= bits - 1; ++population; }
        if (population == k) write_u16(output, 2 + 2 * emitted++, (uint16_t)mask);
    }
    return (int64_t)count;
}
