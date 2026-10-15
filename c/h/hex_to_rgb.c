#include <stddef.h>
#include <stdint.h>

static int64_t hex_nibble(int64_t value) {
    if (value >= '0' && value <= '9') return value - '0';
    if (value >= 'A' && value <= 'F') return value - 'A' + 10;
    if (value >= 'a' && value <= 'f') return value - 'a' + 10;
    return -1;
}

int64_t hex_to_rgb(const int64_t *input, size_t length) {
    if (input == NULL || length != 6) return -1;
    int64_t packed_rgb = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t nibble = hex_nibble(input[index]);
        if (nibble < 0) return -1;
        packed_rgb = (packed_rgb << 4) | nibble;
    }
    return packed_rgb;
}
