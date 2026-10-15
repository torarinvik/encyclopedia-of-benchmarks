/* Least cyclic shift index using Duval's linear-time scan. */
#include <stddef.h>
#include <stdint.h>

int64_t duval(const int64_t *values, size_t length) {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    if (values == NULL) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }

    size_t i = 0, answer = 0;
    while (i < length) {
        answer = i;
        size_t j = i + 1, k = i;
        while (j < 2 * length && values[j % length] >= values[k % length]) {
            if (values[k % length] < values[j % length]) k = i;
            else ++k;
            ++j;
        }
        while (i <= k) i += j - k;
    }
    return (int64_t)answer;
}
