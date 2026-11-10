#include <stddef.h>
#include <stdint.h>

int64_t minimum_deletions_to_make_string_balanced(const int64_t *values, size_t length) {
    if (length > 256 || (length != 0 && values == NULL)) return -1;
    int64_t a_state = 0;
    int64_t b_state = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = values[index];
        if (value < 0 || value > 1) return -1;
        b_state += value == 0 && b_state < a_state;
        a_state += value;
    }
    return b_state;
}
