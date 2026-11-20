#include <stddef.h>
#include <stdint.h>

enum { MAX_COUNT = 32, MAX_WORDS = 66, MAX_BYTES = 32 };

static int64_t posit8_positive_units(uint8_t code) {
    int cursor = 6;
    int regime_bit = (code >> cursor) & 1;
    int run = 0;
    while (cursor >= 0 && ((code >> cursor) & 1) == regime_bit) {
        ++run;
        --cursor;
    }
    int regime = regime_bit ? run - 1 : -run;
    if (cursor >= 0) --cursor;
    int exponent = 0;
    for (int i = 0; i < 2; ++i) {
        exponent <<= 1;
        if (cursor >= 0) {
            exponent |= (code >> cursor) & 1;
            --cursor;
        }
    }
    int width = cursor + 1;
    int fraction = width ? code & ((1 << width) - 1) : 0;
    int significand = (1 << width) + fraction;
    int shift = 4 * regime + exponent + 24 - width;
    return (int64_t)significand << shift;
}

static int posit8_compare_ratio_to_unit(uint64_t scaled_numerator, uint64_t denominator, uint64_t unit) {
    uint64_t quotient = scaled_numerator / denominator;
    uint64_t remainder = scaled_numerator % denominator;
    if (quotient < unit) return -1;
    if (quotient > unit) return 1;
    return remainder == 0 ? 0 : 1;
}

static uint8_t posit8_encode_one(int64_t numerator, int64_t denominator) {
    if (numerator == 0) return 0;
    int negative = numerator < 0;
    uint64_t magnitude = (uint64_t)(negative ? -numerator : numerator);
    uint64_t scaled = magnitude << 24;
    uint8_t chosen;
    if (posit8_compare_ratio_to_unit(scaled, (uint64_t)denominator, 1) <= 0) {
        chosen = 1;
    } else if (posit8_compare_ratio_to_unit(scaled, (uint64_t)denominator,
                                           (uint64_t)posit8_positive_units(127)) >= 0) {
        chosen = 127;
    } else {
        int low = 1, high = 127;
        while (low < high) {
            int middle = low + (high - low) / 2;
            uint64_t value = (uint64_t)posit8_positive_units((uint8_t)middle);
            if (posit8_compare_ratio_to_unit(scaled, (uint64_t)denominator, value) > 0) low = middle + 1;
            else high = middle;
        }
        int upper = low, lower = upper - 1;
        uint64_t midpoint = (uint64_t)posit8_positive_units((uint8_t)lower) +
                            (uint64_t)posit8_positive_units((uint8_t)upper);
        int midpoint_comparison = posit8_compare_ratio_to_unit(scaled << 1, (uint64_t)denominator, midpoint);
        chosen = (uint8_t)(midpoint_comparison < 0 ? lower :
                           midpoint_comparison > 0 ? upper :
                           ((lower & 1) == 0 ? lower : upper));
    }
    return negative ? (uint8_t)(0u - chosen) : chosen;
}

int64_t posit8_rational_encoder(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_WORDS) return -1;
    int64_t count_word = input[0];
    if (count_word < 0 || count_word > MAX_COUNT || length != 1 + (size_t)count_word * 2) return -1;
    size_t count = (size_t)count_word;
    for (size_t i = 0; i < count; ++i) {
        int64_t numerator = input[1 + 2 * i], denominator = input[2 + 2 * i];
        if (numerator < -INT64_C(2147483648) || numerator > INT64_C(2147483648) ||
            denominator < 1 || denominator > INT64_C(2147483648)) return -1;
    }
    if (output == NULL || capacity < count) return -2;
    uint8_t staged[MAX_BYTES];
    for (size_t i = 0; i < count; ++i)
        staged[i] = posit8_encode_one(input[1 + 2 * i], input[2 + 2 * i]);
    for (size_t i = 0; i < count; ++i) output[i] = staged[i];
    return (int64_t)count;
}
