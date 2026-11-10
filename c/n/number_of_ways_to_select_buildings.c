#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

int64_t number_of_ways_to_select_buildings(const int64_t *values, size_t length) {
    if (length == 0) return 0;
    if (values == NULL || length > MAX_LENGTH) return -1;
    uint64_t different_bits = 0;
    uint32_t zeros = 0;
    uint32_t ones = 0;
    uint32_t zero_one = 0;
    uint32_t one_zero = 0;
    uint64_t ways = 0;
    for (size_t index = 0; index < length; ++index) {
        uint64_t byte = (uint64_t)values[index] ^ 48;
        different_bits |= byte;
        bool is_one = (byte & 1) != 0;
        ways += (uint64_t)(is_one ? one_zero : zero_one);
        zero_one += is_one ? zeros : 0;
        one_zero += is_one ? 0 : ones;
        zeros += is_one ? 0 : 1;
        ones += is_one ? 1 : 0;
    }
    if (different_bits > 1) return -1;
    return (int64_t)ways;
}
