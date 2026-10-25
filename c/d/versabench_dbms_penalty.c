#include <stddef.h>
#include <stdint.h>

int64_t versabench_dbms_penalty(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 17 || length != 16) return -1;
    for (size_t box = 0; box < 2; ++box) {
        size_t at = box * 8;
        for (size_t d = 0; d < 4; ++d) {
            int64_t lo = values[at+d], hi = values[at+4+d];
            if (lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo >= hi) return -1;
        }
    }
    int64_t union_volume = 1, first_volume = 1;
    for (size_t d = 0; d < 4; ++d) {
        int64_t a_lo = values[d], a_hi = values[4+d];
        int64_t b_lo = values[8+d], b_hi = values[12+d];
        int64_t lo = a_lo < b_lo ? a_lo : b_lo;
        int64_t hi = a_hi > b_hi ? a_hi : b_hi;
        union_volume *= hi - lo;
        first_volume *= a_hi - a_lo;
    }
    return union_volume - first_volume;
}
