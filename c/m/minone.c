#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define MIN_VALUE (-INT64_C(1000000))
#define MAX_VALUE INT64_C(1000000)

int64_t minone(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    int64_t total = 0;
    for (size_t i = 0; i < length; ++i) {
        const int64_t value = input[i];
        if (value < MIN_VALUE || value > MAX_VALUE) return -1;
        total += value * value;
    }
    return total;
}
