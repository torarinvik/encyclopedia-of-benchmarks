#include <stddef.h>
#include <stdint.h>

int64_t nmea_xor_checksum(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > 78) return -1;
    const int64_t payload_length = values[0];
    if (payload_length < 0 || payload_length > 76 ||
        (size_t)payload_length + 1 != length) return -1;

    uint8_t checksum = 0;
    for (size_t i = 1; i < length; ++i) {
        if (values[i] < 0 || values[i] > 127) return -1;
        checksum ^= (uint8_t)values[i];
    }
    return checksum;
}
