#include <stdint.h>

#define MAX_ORDER 30
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

int64_t magic_square_singly_even_strachey(int64_t n)
{
    if (n < 6 || n > MAX_ORDER || n % 4 != 2) return -1;
    const int order = (int)n;
    const int half = order / 2;
    const int k = half / 2;
    const int block_size = half * half;
    int32_t odd[ MAX_ORDER * MAX_ORDER ] = {0};
    int32_t square[MAX_ORDER * MAX_ORDER] = {0};

    int row = 0;
    int column = half / 2;
    odd[row * MAX_ORDER + column] = 1;
    for (int value = 2; value <= block_size; ++value) {
        const int next_row = (row - 1 + half) % half;
        const int next_column = (column + 1) % half;
        if (odd[next_row * MAX_ORDER + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            row = (row + 1) % half;
        }
        odd[row * MAX_ORDER + column] = value;
    }

    for (int r = 0; r < half; ++r) {
        for (int c = 0; c < half; ++c) {
            const int32_t value = odd[r * MAX_ORDER + c];
            square[r * MAX_ORDER + c] = value;
            square[r * MAX_ORDER + half + c] = value + 2 * block_size;
            square[(half + r) * MAX_ORDER + c] = value + 3 * block_size;
            square[(half + r) * MAX_ORDER + half + c] = value + block_size;
        }
    }

    for (int r = 0; r < half; ++r) {
        for (int c = 0; c < k; ++c) {
            const int top = r * MAX_ORDER + c;
            const int bottom = (half + r) * MAX_ORDER + c;
            const int32_t saved = square[top];
            square[top] = square[bottom];
            square[bottom] = saved;
        }
        for (int c = half - (k - 1); c < half; ++c) {
            const int top = r * MAX_ORDER + half + c;
            const int bottom = (half + r) * MAX_ORDER + half + c;
            const int32_t saved = square[top];
            square[top] = square[bottom];
            square[bottom] = saved;
        }
    }

    {
        const int top = k * MAX_ORDER;
        const int bottom = (half + k) * MAX_ORDER;
        const int32_t saved = square[top];
        square[top] = square[bottom];
        square[bottom] = saved;
    }
    {
        const int top = k * MAX_ORDER + k;
        const int bottom = (half + k) * MAX_ORDER + k;
        const int32_t saved = square[top];
        square[top] = square[bottom];
        square[bottom] = saved;
    }

    uint64_t hash = hash_byte(FNV_OFFSET, (uint8_t)order);
    for (int r = 0; r < order; ++r) {
        for (int c = 0; c < order; ++c) {
            hash = hash_i32(hash, square[r * MAX_ORDER + c]);
        }
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
