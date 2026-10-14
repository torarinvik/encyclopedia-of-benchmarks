// XOR reduction for the signed 32-bit single-number contract.
#include <cstddef>
#include <cstdint>
extern "C" int64_t single_number(const int64_t *values, std::size_t length) {
    if (length == 0 || length > 257) return -2147483649LL;
    int64_t bits = 0;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -2147483649LL;
        const int64_t word = values[i] < 0 ? values[i] + 4294967296LL : values[i];
        bits ^= word;
    }
    return bits > INT32_MAX ? bits - 4294967296LL : bits;
}
