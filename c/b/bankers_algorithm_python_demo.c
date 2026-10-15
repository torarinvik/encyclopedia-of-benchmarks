/* Preserve the duplicate-need bookkeeping in the pinned Python demonstration. */
#include <stddef.h>
#include <stdint.h>

#define MAX_PROCESSES 16
#define MAX_RESOURCES 8
#define MAX_INPUT_LENGTH 266

int64_t bankers_algorithm_python_demo(const int64_t *values, size_t length)
{
    if (values == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    int64_t nv = values[0], mv = values[1];
    if (nv < 1 || nv > MAX_PROCESSES || mv < 1 || mv > MAX_RESOURCES) return -1;
    size_t n = (size_t)nv, m = (size_t)mv, aoff = 2 + m, moff = aoff + n * m;
    if (length != moff + n * m) return -1;
    int64_t work[MAX_RESOURCES] = {0};
    for (size_t r = 0; r < m; ++r) {
        int64_t claim = values[2 + r];
        if (claim < 0 || claim > 100) return -1;
        work[r] = claim;
    }
    for (size_t p = 0; p < n; ++p) for (size_t r = 0; r < m; ++r) {
        size_t i = p * m + r;
        int64_t allocation = values[aoff + i], maximum = values[moff + i];
        if (allocation < 0 || allocation > 100 || maximum < 0 || maximum > 100 || allocation > maximum) return -1;
        work[r] -= allocation;
    }
    for (size_t r = 0; r < m; ++r) if (work[r] < 0) return -1;
    size_t first_equal[MAX_PROCESSES] = {0}, remaining[MAX_PROCESSES] = {0};
    for (size_t p = 0; p < n; ++p) {
        first_equal[p] = p; remaining[p] = p;
        for (size_t q = 0; q < p; ++q) {
            int equal = 1;
            for (size_t r = 0; r < m; ++r) {
                size_t pi = p * m + r, qi = q * m + r;
                if (values[moff + pi] - values[aoff + pi] != values[moff + qi] - values[aoff + qi]) { equal = 0; break; }
            }
            if (equal) { first_equal[p] = first_equal[q]; break; }
        }
    }
    size_t count = n;
    while (count) {
        size_t selected = count;
        for (size_t i = 0; i < count; ++i) {
            size_t p = remaining[i]; int feasible = 1;
            for (size_t r = 0; r < m; ++r) {
                size_t j = p * m + r;
                if (values[moff + j] - values[aoff + j] > work[r]) { feasible = 0; break; }
            }
            if (feasible) { selected = i; break; }
        }
        if (selected == count) return 0;
        size_t p = remaining[selected], mapped = first_equal[p];
        for (size_t r = 0; r < m; ++r) work[r] += values[aoff + mapped * m + r];
        for (size_t i = selected + 1; i < count; ++i) remaining[i - 1] = remaining[i];
        --count;
    }
    return 1;
}
