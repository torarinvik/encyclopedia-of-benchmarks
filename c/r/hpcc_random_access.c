#include <stddef.h>
#include <stdint.h>

#define MAX_TABLE_SIZE 256
#define DIGEST_MASK UINT64_C(0x7fffffffffffffff)

int64_t hpcc_random_access(const int64_t *input, size_t length) {
    if (input == NULL || length != 1) return -1;
    const int64_t size_value = input[0];
    if (size_value < 2 || size_value > MAX_TABLE_SIZE
        || (size_value & (size_value - 1)) != 0) return -1;

    const size_t size = (size_t)size_value;
    uint64_t table[MAX_TABLE_SIZE];
    for (size_t index = 0; index < size; ++index) table[index] = (uint64_t)index;

    uint64_t ran = UINT64_C(1);
    for (size_t update = 0; update < 4 * size; ++update) {
        const uint64_t feedback = (ran >> 63) != 0 ? UINT64_C(7) : UINT64_C(0);
        ran = (ran << 1) ^ feedback;
        table[ran & (uint64_t)(size - 1)] ^= ran;
    }

    uint64_t digest = 0;
    for (size_t index = 0; index < size; ++index) {
        digest += (uint64_t)(index + 1) * table[index];
    }
    return (int64_t)(digest & DIGEST_MASK);
}
