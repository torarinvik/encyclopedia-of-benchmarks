/* Sum an inclusive arithmetic progression from packed [from, to, step]. */
#include <stddef.h>
#include <stdint.h>

int64_t arithmetic_progression(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return -1;
    const int64_t from = values[0], to = values[1], step = values[2];
    if (from < -1000000 || from > 1000000 || to < -1000000 || to > 1000000 ||
        step < -1000000 || step > 1000000 || step == 0) return -1;
    if ((from < to && step < 0) || (from > to && step > 0)) return -1;
    const int64_t count = (to - from) / step;
    const int64_t last = from + count * step;
    return ((count + 1) * (from + last)) / 2;
}
