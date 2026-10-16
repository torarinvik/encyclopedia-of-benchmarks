/* Dispatch the seven pinned Python endianness helpers. */
#include <stddef.h>
#include <stdint.h>

static int64_t signed_u64(uint64_t bits) {
    if (bits <= (uint64_t)INT64_MAX) return (int64_t)bits;
    return -1 - (int64_t)(UINT64_MAX - bits);
}

static uint64_t swap_bytes(uint64_t bits, size_t count) {
    uint64_t reversed = 0;
    for (size_t i = 0; i < count; ++i) {
        reversed = (reversed << 8) | (bits & UINT64_C(0xff));
        bits >>= 8;
    }
    return reversed;
}

int64_t endianness(const int64_t *input, size_t length) {
    if (input == NULL || length == 0) return -1;
    const int64_t operation = input[0];
    if (operation == 0 || operation == 1 || operation == 2) {
        if (length != 2) return -1;
        const int64_t value = input[1];
        if (operation == 0) {
            if (value < 0 || value > 65535) return -1;
            return (int64_t)swap_bytes((uint64_t)value, 2);
        }
        if (operation == 1) {
            if (value < 0 || (uint64_t)value > UINT64_C(0xffffffff)) return -1;
            return (int64_t)swap_bytes((uint64_t)value, 4);
        }
        return signed_u64(swap_bytes((uint64_t)value, 8));
    }
    if (operation == 3 || operation == 4) {
        if (length < 3 || input[1] < 1 || input[1] > 8 || length != (size_t)input[1] + 2) return -1;
        uint64_t result = 0;
        const size_t count = (size_t)input[1];
        for (size_t i = 0; i < count; ++i) {
            const int64_t byte = input[i + 2];
            if (byte < 0 || byte > 255) return -1;
            const size_t shift = operation == 3 ? 8 * i : 8 * (count - 1 - i);
            result |= (uint64_t)byte << shift;
        }
        return signed_u64(result);
    }
    if (operation == 5 || operation == 6) {
        if (length != 3 || input[2] < 1 || input[2] > 8) return -1;
        const size_t count = (size_t)input[2];
        const uint64_t value = (uint64_t)input[1];
        if (count < 8 && (input[1] < 0 || (value >> (8 * count)) != 0)) return -1;
        return signed_u64(operation == 5 ? value : swap_bytes(value, count));
    }
    return -1;
}
