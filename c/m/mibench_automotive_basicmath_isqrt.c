#include <stddef.h>
#include <stdint.h>

int64_t mibench_automotive_basicmath_isqrt(const int64_t *input, size_t length) {
    if (input == NULL || length != 1 || input[0] < 0 || input[0] > 65535) return -1;
    uint32_t x = (uint32_t)input[0];
    uint32_t root = 0, remainder = 0;
    for (unsigned int step = 0; step < 32; ++step) {
        remainder = (remainder << 2) + (x >> 30);
        x <<= 2;
        root <<= 1;
        const uint32_t trial = (root << 1) + 1;
        if (remainder >= trial) {
            remainder -= trial;
            ++root;
        }
    }
    return (int64_t)root;
}
