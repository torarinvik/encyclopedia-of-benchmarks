// Count stones whose ASCII byte appears in the unique-jewel set.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_jewels_length = 127;
constexpr std::size_t max_stones_length = 4096;
constexpr std::size_t max_packed_length = 2 + max_jewels_length + max_stones_length;
}

extern "C" std::int64_t jewels_and_stones(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_packed_length) return -1;
    if (input[0] < 0 || input[0] > 127 || input[1] < 0 || input[1] > 4096) return -1;
    const auto jewel_count = static_cast<std::size_t>(input[0]);
    const auto stone_count = static_cast<std::size_t>(input[1]);
    if (length != 2 + jewel_count + stone_count) return -1;
    std::array<std::int64_t, 128> counts{};
    for (std::size_t index = 0; index < jewel_count; ++index) {
        const auto value = input[2 + index];
        if (value < 1 || value > 127 || counts[static_cast<std::size_t>(value)] != 0) return -1;
        counts[static_cast<std::size_t>(value)] = 1;
    }
    std::int64_t total = 0;
    const auto stone_start = 2 + jewel_count;
    for (std::size_t index = 0; index < stone_count; ++index) {
        const auto value = input[stone_start + index];
        if (value < 1 || value > 127) return -1;
        total += counts[static_cast<std::size_t>(value)];
    }
    return total;
}
