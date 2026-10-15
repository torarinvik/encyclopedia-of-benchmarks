/* Sum an inclusive arithmetic progression from packed [from, to, step]. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t arithmetic_progression(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 3) return -1;
    const std::int64_t from = values[0], to = values[1], step = values[2];
    if (from < -1000000 || from > 1000000 || to < -1000000 || to > 1000000 ||
        step < -1000000 || step > 1000000 || step == 0) return -1;
    if ((from < to && step < 0) || (from > to && step > 0)) return -1;
    const std::int64_t count = (to - from) / step;
    const std::int64_t last = from + count * step;
    return ((count + 1) * (from + last)) / 2;
}
