#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 32

int64_t is_ip_v4_address_valid(const int64_t *bytes, size_t length)
{
    if ((bytes == NULL && length != 0) || length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (bytes[index] < 0 || bytes[index] > 127) return -1;
    }
    size_t segment_count = 0;
    size_t digit_count = 0;
    int64_t octet = 0;
    int leading_zero = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = bytes[index];
        if (value == '.') {
            if (digit_count == 0 || octet > 255 || segment_count >= 3) return 0;
            ++segment_count;
            digit_count = 0;
            octet = 0;
            leading_zero = 0;
        } else {
            if (value < '0' || value > '9') return 0;
            if (digit_count == 0) leading_zero = value == '0';
            else if (leading_zero) return 0;
            octet = octet * 10 + value - '0';
            if (octet > 255) return 0;
            ++digit_count;
            if (digit_count > 3) return 0;
        }
    }
    return segment_count == 3 && digit_count > 0 && octet <= 255;
}
