#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr int64_t modulus = 1000000007; }

extern "C" int64_t number_of_subarrays_with_odd_sum(const int64_t *values, size_t length) {
    if (length > 100000 || (length != 0 && values == nullptr)) return -1;
    int64_t even_prefixes = 1;
    int64_t odd_prefixes = 0;
    int64_t result = 0;
    int parity = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < std::numeric_limits<int32_t>::min()
                || value > std::numeric_limits<int32_t>::max()) return -1;
        if (value % 2 != 0) parity = 1 - parity;
        if (parity == 0) {
            result = (result + odd_prefixes) % modulus;
            ++even_prefixes;
        } else {
            result = (result + even_prefixes) % modulus;
            ++odd_prefixes;
        }
    }
    return result;
}
