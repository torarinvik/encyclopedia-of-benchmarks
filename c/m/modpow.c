#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT INT64_MIN
#define MAX_PARSEABLE_INPUT_LENGTH 4
#define MAX_COMPONENT 89000000
#define MAX_EXPONENT 64
int64_t modpow(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    if (length != 3) return INVALID_RESULT;
    int64_t base = input[0], exponent = input[1], modulus = input[2];
    if (base < 0 || base > MAX_COMPONENT || exponent < 0 || exponent > MAX_EXPONENT
        || modulus < 1 || modulus > MAX_COMPONENT) return INVALID_RESULT;
    if (exponent == 0) {
        if (base == 0) return INVALID_RESULT;
        return 1 % modulus;
    }
    if (base == 0) return 0;
    int64_t result = 1 % modulus;
    while (exponent > 0) {
        if (exponent % 2 == 1) {
            result = (result * base) % modulus;
            exponent -= 1;
        } else {
            base = (base * base) % modulus;
            exponent /= 2;
        }
    }
    return result;
}
