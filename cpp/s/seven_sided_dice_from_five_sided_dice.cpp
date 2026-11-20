#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxDraws = 256;
constexpr std::size_t kMaxInputLength = kMaxDraws + 2;
}

extern "C" std::int64_t seven_sided_dice_from_five_sided_dice(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > kMaxInputLength) return -1;
    const std::int64_t draw_count_value = input[0];
    if (draw_count_value < 0 || draw_count_value > static_cast<std::int64_t>(kMaxDraws) ||
        length != static_cast<std::size_t>(draw_count_value) + 1) return -1;
    const auto draw_count = static_cast<std::size_t>(draw_count_value);
    for (std::size_t index = 0; index < draw_count; ++index)
        if (input[index + 1] < 0 || input[index + 1] > 4) return -1;

    std::array<std::uint8_t, kMaxDraws> staged{};
    std::size_t written = 0;
    std::int64_t value = 0;
    std::int64_t range = 1;
    for (std::size_t index = 0; index < draw_count; ++index) {
        value = 5 * value + input[index + 1];
        range *= 5;
        while (range >= 7) {
            const std::int64_t accepted = range - range % 7;
            if (value < accepted) {
                staged[written++] = static_cast<std::uint8_t>(value % 7 + 1);
                value /= 7;
                range = accepted / 7;
            } else {
                value -= accepted;
                range -= accepted;
            }
        }
    }

    if (output == nullptr || capacity < written) return -2;
    for (std::size_t index = 0; index < written; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(written);
}
