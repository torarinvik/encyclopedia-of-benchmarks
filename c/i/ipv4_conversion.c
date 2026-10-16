#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

int64_t ipv4_conversion(const int64_t *input, size_t length) {
    if (input == NULL || length != 4) return INVALID_RESULT;
    int64_t address = 0;
    for (size_t index = 0; index < 4; ++index) {
        const int64_t octet = input[index];
        if (octet < 0 || octet > 255) return INVALID_RESULT;
        address = address * 256 + octet;
    }
    return address;
}
