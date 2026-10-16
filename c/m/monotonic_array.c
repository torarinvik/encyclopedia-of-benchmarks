#include <stddef.h>
#include <stdint.h>

int64_t is_monotonic(const int64_t *values, size_t length) {
    if (length > 256 || (values == NULL && length != 0)) {
        return -1;
    }

    for (size_t i = 1; i < length; ++i) {
        if (values[i - 1] > values[i]) {
            for (size_t j = 1; j < length; ++j) {
                if (values[j - 1] < values[j]) {
                    return 0;
                }
            }
            return 1;
        }
    }
    return 1;
}
