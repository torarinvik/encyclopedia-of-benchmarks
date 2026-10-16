#include <stddef.h>
#include <stdint.h>

void reversort(int64_t *values, size_t length) {
    for (size_t index = 0; index + 1 < length; ++index) {
        size_t minimum = index;
        for (size_t probe = index + 1; probe < length; ++probe)
            if (values[probe] < values[minimum]) minimum = probe;
        for (size_t left = index, right = minimum; left < right; ++left, --right) {
            const int64_t temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
        }
    }
}
