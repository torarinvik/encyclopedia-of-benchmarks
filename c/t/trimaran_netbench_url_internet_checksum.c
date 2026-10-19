/* Modified source-related port of NetBench url.c; see bundled LICENSE_NOTICE.txt. */
#include <stddef.h>
#include <stdint.h>

#define MAX_BYTES 64

int64_t trimaran_netbench_url_internet_checksum(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_BYTES + 2) return -1;
    const int64_t mode = values[0], count_value = values[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_BYTES ||
        length != (size_t)count_value + 2) return -1;
    const size_t count = (size_t)count_value;
    for (size_t i = 0; i < count; ++i) if (values[i + 2] < 0 || values[i + 2] > 255) return -1;
    uint64_t sum = 0;
    size_t i = 0;
    for (; i + 1 < count; i += 2) {
        const uint64_t word = (uint64_t)values[i + 2] | ((uint64_t)values[i + 3] << 8);
        sum -= word + 1;
    }
    if (i < count) sum += (uint64_t)values[i + 2];
    while ((sum >> 16) != 0) sum = (sum & UINT64_C(0xffff)) + (sum >> 16);
    if (mode == 1) sum = ((sum >> 8) | ((sum << 8) & UINT64_C(0xff00))) & UINT64_C(0xffff);
    return (int64_t)sum;
}
