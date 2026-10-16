#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64
#define MAX_PARSEABLE_INPUT_LENGTH 65
#define INVALID_RESULT (-2147483649LL)
#define UINT32_MODULUS 4294967296ULL

int64_t hexa_decimal_to_decimal(const int64_t *input, size_t length) {
    if (length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length == 0) return 0;
    if (length > MAX_INPUT_LENGTH || input == NULL) return INVALID_RESULT;

    uint64_t accumulator = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t code = input[index];
        int64_t digit;
        if (code >= 48 && code <= 57) digit = code - 48;
        else if (code >= 65 && code <= 70) digit = code - 55;
        else if (code >= 97 && code <= 102) digit = code - 87;
        else return INVALID_RESULT;
        accumulator = (accumulator * 16 + (uint64_t)digit) % UINT32_MODULUS;
    }
    if (accumulator <= 2147483647ULL) return (int64_t)accumulator;
    return (int64_t)accumulator - (int64_t)UINT32_MODULUS;
}
