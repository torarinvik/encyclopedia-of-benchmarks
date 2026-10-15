#include <stddef.h>
#include <stdint.h>

#define MODULUS 1000000007LL

int64_t number_of_subarrays_with_odd_sum(const int64_t *values, size_t length) {
    if (length > 100000 || (length != 0 && values == NULL)) return -1;
    int64_t even_prefixes = 1;
    int64_t odd_prefixes = 0;
    int64_t result = 0;
    int parity = 0;
    for (size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (value % 2 != 0) parity = 1 - parity;
        if (parity == 0) {
            result = (result + odd_prefixes) % MODULUS;
            ++even_prefixes;
        } else {
            result = (result + even_prefixes) % MODULUS;
            ++odd_prefixes;
        }
    }
    return result;
}
