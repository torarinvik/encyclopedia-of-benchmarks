#include <stdint.h>

#define MAX_ORDER 31
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

int64_t magic_square(int64_t n)
{
    if (n < 1 || n > MAX_ORDER || n % 2 == 0) return -1;
    const int order = (int)n;
    int32_t square[MAX_ORDER * MAX_ORDER] = {0};
    int row = order / 2;
    int column = order - 1;
    square[row * MAX_ORDER + column] = 1;

    for (int value = 2; value <= order * order; ++value) {
        const int next_row = (row - 1 + order) % order;
        const int next_column = (column + 1) % order;
        if (square[next_row * MAX_ORDER + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            column = (column - 1 + order) % order;
        }
        square[row * MAX_ORDER + column] = value;
    }

    uint64_t hash = hash_byte(FNV_OFFSET, (uint8_t)order);
    for (int r = 0; r < order; ++r) {
        for (int c = 0; c < order; ++c) {
            hash = hash_i32(hash, square[r * MAX_ORDER + c]);
        }
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
