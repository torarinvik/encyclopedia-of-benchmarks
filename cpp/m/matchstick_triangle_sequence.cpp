#include <cstdint>

extern "C" std::int64_t matchstick_triangle_sequence(std::int64_t n) {
    if (n < 0 || n > 1000000) return -1;
    return (n * (n + 2) * (2 * n + 1)) / 8;
}
