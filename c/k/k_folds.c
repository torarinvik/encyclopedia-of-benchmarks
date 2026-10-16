#include <stddef.h>
#include <stdint.h>

int64_t k_folds(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return -1;
    const int64_t sample_count = values[0], fold_count = values[1];
    if (sample_count < 1 || sample_count > 12 || fold_count < 1 || fold_count > 12) return -1;
    const int64_t width = (sample_count + fold_count - 1) / fold_count;
    uint64_t result = (uint64_t)sample_count << 48;
    for (int64_t index = 0; index < sample_count; ++index) {
        const uint64_t fold = (uint64_t)(index + width) / (uint64_t)width;
        result |= fold << (4 * (unsigned)index);
    }
    return (int64_t)result;
}
