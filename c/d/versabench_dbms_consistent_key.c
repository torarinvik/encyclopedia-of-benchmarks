#include <stddef.h>
#include <stdint.h>

int64_t versabench_dbms_consistent_key(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 17 || length != 16) return -1;
    for (size_t box = 0; box < 2; ++box) {
        const size_t base = box * 8;
        for (size_t d = 0; d < 4; ++d) {
            const int64_t lower = values[base + d], upper = values[base + 4 + d];
            if (lower < -8 || lower > 8 || upper < -8 || upper > 8 || lower > upper) return -1;
        }
    }
    for (size_t d = 0; d < 4; ++d)
        if (values[d] > values[12 + d] || values[8 + d] > values[4 + d]) return 0;
    return 1;
}
