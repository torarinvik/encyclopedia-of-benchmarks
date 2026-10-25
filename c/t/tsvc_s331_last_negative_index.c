#include <stddef.h>
#include <stdint.h>

#define S331_MAX_N 256
#define S331_MAX_VALUE INT64_C(1000000)
int64_t tsvc_s331_last_negative_index(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 1 + S331_MAX_N) return -1;
    if (input[0] < 1 || input[0] > S331_MAX_N || length != 1 + (size_t)input[0]) return -1;
    int64_t result = 0;
    for (size_t i = 0; i < (size_t)input[0]; ++i) {
        const int64_t value = input[1 + i];
        if (value < -S331_MAX_VALUE || value > S331_MAX_VALUE) return -1;
        if (value < 0) result = (int64_t)i + 1;
    }
    return result;
}
