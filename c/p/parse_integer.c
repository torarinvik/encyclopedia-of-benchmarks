#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

static int64_t signed_int32(uint32_t bits) {
    return bits <= INT32_MAX ? (int64_t)bits : (int64_t)bits - INT64_C(4294967296);
}

int64_t parse_integer(const int64_t *bytes, size_t length) {
    if (bytes == NULL || length == 0 || length > 64) return INVALID_RESULT;
    for (size_t i = 0; i < length; ++i) if (bytes[i] < 0 || bytes[i] > 127) return INVALID_RESULT;
    const int negative = bytes[0] == '-';
    size_t index = (bytes[0] == '-' || bytes[0] == '+') ? 1 : 0;
    uint32_t number = 0;
    for (; index < length; ++index) {
        if (bytes[index] < '0' || bytes[index] > '9') return INVALID_RESULT;
        number = number * UINT32_C(10) + (uint32_t)(bytes[index] - '0');
    }
    if (negative) number = UINT32_C(0) - number;
    return signed_int32(number);
}
