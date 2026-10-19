#include <cstdint>

namespace {
constexpr std::int64_t max_input = 12;

std::int64_t tak(std::int64_t x, std::int64_t y, std::int64_t z) noexcept {
    if (y < x) return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
    return z;
}
}

extern "C" std::int64_t takeuchi(std::int64_t x, std::int64_t y, std::int64_t z) noexcept {
    if (x < 0 || x > max_input || y < 0 || y > max_input || z < 0 || z > max_input) return -1;
    return tak(x, y, z);
}
