/* Least cyclic rotation by two-candidate elimination. */
#include <stddef.h>
#include <stdint.h>

int64_t minimum_string_representation(const int64_t *values, size_t length) {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    if (values == NULL) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }

    size_t left = 0, right = 1, matched = 0;
    while (left < length && right < length && matched < length) {
        int64_t a = values[(left + matched) % length];
        int64_t b = values[(right + matched) % length];
        if (a == b) {
            ++matched;
            continue;
        }
        if (a > b) {
            left += matched + 1;
            if (left == right) ++left;
        } else {
            right += matched + 1;
            if (left == right) ++right;
        }
        matched = 0;
    }
    return (int64_t)(left < right ? left : right);
}
