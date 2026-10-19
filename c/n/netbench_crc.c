#include <stddef.h>
#include <stdint.h>

#define NETBENCH_CRC_MAX_LENGTH 256
#define NETBENCH_CRC_POLYNOMIAL UINT64_C(0x04c11db7)
#define NETBENCH_CRC_OUTPUT_MASK UINT64_C(0xffffffff)

int64_t netbench_crc(const int64_t *values, size_t length) {
    if (length > NETBENCH_CRC_MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 255) return -1;

    uint64_t table[256];
    for (uint64_t byte = 0; byte < 256; ++byte) {
        uint64_t remainder = byte << 24;
        for (unsigned bit = 0; bit < 8; ++bit) {
            if ((remainder & UINT64_C(0x80000000)) != 0)
                remainder = (remainder << 1) ^ NETBENCH_CRC_POLYNOMIAL;
            else
                remainder <<= 1;
        }
        table[byte] = remainder;
    }

    uint64_t crc = 0;
    for (size_t index = 0; index < length; ++index) {
        const uint64_t byte = (uint64_t)values[index];
        const size_t table_index = (size_t)(((crc >> 24) ^ byte) & UINT64_C(0xff));
        crc = (crc << 8) ^ table[table_index];
    }
    return (int64_t)(crc & NETBENCH_CRC_OUTPUT_MASK);
}
