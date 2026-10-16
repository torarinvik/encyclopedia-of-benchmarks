#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t training[11][4] = {
    {2, 99, 255, 1}, {37, 44, 58, 0}, {139, 169, 229, 1},
    {14, 255, 10, 1}, {2, 28, 1, 0}, {20, 33, 20, 0},
    {252, 227, 65, 1}, {71, 65, 24, 0}, {168, 80, 80, 1},
    {119, 35, 90, 0}, {186, 13, 126, 1},
};
}

extern "C" std::int64_t brightness(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length != 3) return -1;
    for (std::size_t channel = 0; channel < 3; ++channel) {
        if (input[channel] < 0 || input[channel] > 255) return -1;
    }

    std::int64_t best_distance = 195076;
    std::int64_t best_label = -1;
    for (std::size_t sample = 0; sample < 11; ++sample) {
        const auto red_delta = input[0] - training[sample][0];
        const auto green_delta = input[1] - training[sample][1];
        const auto blue_delta = input[2] - training[sample][2];
        const auto distance = red_delta * red_delta + green_delta * green_delta + blue_delta * blue_delta;
        if (distance < best_distance) {
            best_distance = distance;
            best_label = training[sample][3];
        }
    }
    return best_label;
}
