#include <stdint.h>

#define MAX_ITERATIONS INT64_C(1125000)

static const uint8_t nibble_bits[16] = {
    0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4
};
static const uint32_t initial_seeds[7] = {1, 1, 1, 1, 1, 1, 1};

static int count_kernighan(uint32_t value) {
    int count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}

static int count_parallel(uint32_t value) {
    value = ((value & UINT32_C(0xAAAAAAAA)) >> 1) + (value & UINT32_C(0x55555555));
    value = ((value & UINT32_C(0xCCCCCCCC)) >> 2) + (value & UINT32_C(0x33333333));
    value = ((value & UINT32_C(0xF0F0F0F0)) >> 4) + (value & UINT32_C(0x0F0F0F0F));
    value = ((value & UINT32_C(0xFF00FF00)) >> 8) + (value & UINT32_C(0x00FF00FF));
    value = ((value & UINT32_C(0xFFFF0000)) >> 16) + (value & UINT32_C(0x0000FFFF));
    return (int)value;
}

static int count_recursive_nybbles(uint32_t value) {
    int count = nibble_bits[value & 0xFU];
    return value >> 4 == 0 ? count : count + count_recursive_nybbles(value >> 4);
}

static int count_fixed_nybbles(uint32_t value) {
    int count = 0;
    for (unsigned shift = 0; shift < 32; shift += 4) {
        count += nibble_bits[(value >> shift) & 0xFU];
    }
    return count;
}

static int count_byte(uint32_t value) {
    return nibble_bits[value & 0xFU] + nibble_bits[(value >> 4) & 0xFU];
}

static int count_bw_bytes(uint32_t value) {
    return count_byte(value) + count_byte(value >> 8) +
           count_byte(value >> 24) + count_byte(value >> 16);
}

static int count_ar_bytes(uint32_t value) {
    int count = 0;
    for (unsigned index = 0; index < 4; ++index) {
        count += count_byte(value >> (index * 8));
    }
    return count;
}

static int count_shift_test(uint32_t value) {
    int count = 0;
    for (unsigned bit = 0; bit < 64 && value != 0; ++bit, value >>= 1) {
        count += (int)(value & 1U);
    }
    return count;
}

typedef int (*counter_fn)(uint32_t);

int64_t cbench_automotive_bitcount(int64_t iterations) {
    if (iterations < 0 || iterations > MAX_ITERATIONS) return -1;
    static const counter_fn counters[7] = {
        count_kernighan, count_parallel, count_recursive_nybbles,
        count_fixed_nybbles, count_bw_bytes, count_ar_bytes, count_shift_test
    };
    int64_t result = 0;
    for (unsigned algorithm = 0; algorithm < 7; ++algorithm) {
        uint32_t seed = initial_seeds[algorithm];
        int64_t total = 0;
        for (int64_t iteration = 0; iteration < iterations; ++iteration, seed += 13) {
            total += counters[algorithm](seed);
        }
        result += (int64_t)(algorithm + 1) * total;
    }
    return result;
}
