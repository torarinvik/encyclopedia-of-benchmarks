#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_faces = 8;
constexpr std::int64_t max_dice = 8;
constexpr std::int64_t max_target = 64;
}

extern "C" std::int64_t dice_throw(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1;
    const std::int64_t faces_value = values[0];
    const std::int64_t dice_value = values[1];
    const std::int64_t target_value = values[2];
    if (faces_value < 1 || faces_value > max_faces || dice_value < 1 || dice_value > max_dice ||
        target_value < 0 || target_value > max_target) return -1;
    const auto faces = static_cast<std::size_t>(faces_value);
    const auto dice = static_cast<std::size_t>(dice_value);
    const auto target = static_cast<std::size_t>(target_value);

    std::int64_t table[max_dice + 1][max_target + 1]{};
    for (std::size_t total = 1; total <= faces && total <= target; ++total) table[1][total] = 1;
    for (std::size_t die = 2; die <= dice; ++die) {
        for (std::size_t total = 1; total <= target; ++total) {
            for (std::size_t face = 1; face < total && face <= faces; ++face) {
                table[die][total] += table[die - 1][total - face];
            }
        }
    }
    return table[dice][target];
}
