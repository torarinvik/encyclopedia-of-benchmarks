/* Bounded recursive Ackermann function A(m, n). */
#include <cstdint>

namespace {
std::int64_t ackermann_value(std::int64_t m, std::int64_t n) noexcept {
    if (m == 0) return n + 1;
    if (n == 0) return ackermann_value(m - 1, 1);
    return ackermann_value(m - 1, ackermann_value(m, n - 1));
}
}

extern "C" std::int64_t ackermann(std::int64_t m, std::int64_t n) noexcept {
    if (m < 0 || m > 3 || n < 0 || n > 5) return -1;
    return ackermann_value(m, n);
}
