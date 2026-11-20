#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t kMaxCoordinate = 1'000'000'000;
}

extern "C" std::int64_t infinite_knight_distance(const std::int64_t *input,
                                                   std::size_t length) noexcept {
    if (input == nullptr || length != 2) return -1;
    const auto dx = input[0];
    const auto dy = input[1];
    if (dx < -kMaxCoordinate || dx > kMaxCoordinate ||
        dy < -kMaxCoordinate || dy > kMaxCoordinate) return -1;
    const auto abs_x = dx < 0 ? -dx : dx;
    const auto abs_y = dy < 0 ? -dy : dy;
    const auto large = abs_x > abs_y ? abs_x : abs_y;
    const auto small = abs_x < abs_y ? abs_x : abs_y;
    if (large == 1 && small == 0) return 3;
    if (large == 2 && small == 2) return 4;
    auto distance = (large + 1) / 2;
    const auto diagonal_bound = (large + small + 2) / 3;
    if (diagonal_bound > distance) distance = diagonal_bound;
    if ((large + small - distance) % 2 != 0) ++distance;
    return distance;
}
