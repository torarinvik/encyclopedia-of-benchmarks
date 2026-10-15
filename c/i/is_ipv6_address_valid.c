#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 256

static bool is_hex_digit(int64_t value) {
    return (value >= '0' && value <= '9') || (value >= 'a' && value <= 'f') ||
           (value >= 'A' && value <= 'F');
}

static bool valid_ipv6_text(const int64_t *input, size_t start, size_t length) {
    if (length == 0) return false;
    size_t groups = 0;
    size_t group_length = 0;
    size_t compression_count = 0;
    bool in_group = false;
    for (size_t index = 0; index < length;) {
        int64_t value = input[start + index];
        if (value == ':') {
            if (index + 1 < length && input[start + index + 1] == ':') {
                if ((index > 0 && input[start + index - 1] == ':') ||
                    (index + 2 < length && input[start + index + 2] == ':') ||
                    compression_count != 0) return false;
                if (in_group) {
                    ++groups;
                    in_group = false;
                    group_length = 0;
                } else if (index != 0) {
                    return false;
                }
                ++compression_count;
                index += 2;
                continue;
            }
            if (index == 0 || index + 1 == length || !in_group) return false;
            ++groups;
            in_group = false;
            group_length = 0;
            ++index;
            continue;
        }
        if (!is_hex_digit(value) || group_length == 4) return false;
        ++group_length;
        in_group = true;
        ++index;
    }
    if (in_group) ++groups;
    return compression_count == 0 ? groups == 8 : groups < 8;
}

int64_t is_ipv6_address_valid(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_INPUT_LENGTH) return -1;
    size_t text_length = (size_t)input[0];
    if (length != text_length + 1) return -1;
    for (size_t index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 127) return -1;
    }
    return valid_ipv6_text(input, 1, text_length) ? 1 : 0;
}
