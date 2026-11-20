#include <stdint.h>

#define MIN_ORDER 4
#define MAX_ORDER 64
#define FNV_OFFSET UINT64_C(0xcbf29ce484222325)
#define FNV_PRIME UINT64_C(0x100000001b3)

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ byte) * FNV_PRIME;
}

static uint64_t hash_i32(uint64_t hash, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (unsigned shift = 0; shift < 32; shift += 8) {
        hash = hash_byte(hash, (uint8_t)(bits >> shift));
    }
    return hash;
}

int64_t magic_square_doubly_even_complement(int64_t n)
{
    if (n < MIN_ORDER || n > MAX_ORDER || n % 4 != 0) return -1;
    const int32_t order = (int32_t)n;
    const int32_t ceiling = order * order + 1;
    uint64_t hash = hash_byte(FNV_OFFSET, (uint8_t)order);

    for (int32_t row = 0; row < order; ++row) {
        for (int32_t column = 0; column < order; ++column) {
            int32_t value = row * order + column + 1;
            const int32_t local_row = row % 4;
            const int32_t local_column = column % 4;
            if (local_row == local_column || local_row + local_column == 3) {
                value = ceiling - value;
            }
            hash = hash_i32(hash, value);
        }
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
