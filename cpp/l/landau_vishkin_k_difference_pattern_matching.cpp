#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_pattern = 16;
constexpr std::size_t max_text = 32;
constexpr std::size_t max_errors = 2;
constexpr std::size_t max_valid_input = 3 + max_pattern + max_text;
constexpr std::size_t max_parseable_input = max_valid_input + 1;
constexpr std::size_t diagonal_count = max_text + max_errors + 3;
constexpr std::size_t cost_count = max_errors + 2;
constexpr std::size_t diagonal_slot(int diagonal) noexcept {
    return static_cast<std::size_t>(diagonal + static_cast<int>(max_errors) + 1);
}
}  // namespace

extern "C" int64_t landau_vishkin_k_difference_pattern_matching(
    const int64_t* input, std::size_t length, uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > max_parseable_input) return -1;
    const int64_t raw_m = input[0];
    const int64_t raw_n = input[1];
    const int64_t raw_k = input[2];
    if (raw_m < 1 || raw_m > static_cast<int64_t>(max_pattern) ||
        raw_n < 0 || raw_n > static_cast<int64_t>(max_text) ||
        raw_k < 0 || raw_k > static_cast<int64_t>(max_errors) || raw_k >= raw_m) {
        return -1;
    }
    const auto m = static_cast<std::size_t>(raw_m);
    const auto n = static_cast<std::size_t>(raw_n);
    const auto k = static_cast<int>(raw_k);
    if (length != 3 + m + n) return -1;
    const int64_t* pattern = input + 3;
    const int64_t* text = pattern + m;
    for (std::size_t i = 0; i < m + n; ++i) {
        const int64_t symbol = i < m ? pattern[i] : text[i - m];
        if (symbol < 0 || symbol > 3) return -1;
    }
    if (output == nullptr || capacity < n) return -2;

    std::array<std::array<int64_t, cost_count>, diagonal_count> frontier{};
    for (auto& diagonal : frontier) diagonal.fill(-1);
    for (int d = -(k + 1); d < 0; ++d) {
        const int magnitude = -d;
        frontier[diagonal_slot(d)][static_cast<std::size_t>(magnitude)] = magnitude - 1;
        frontier[diagonal_slot(d)][static_cast<std::size_t>(magnitude - 1)] = magnitude - 2;
    }

    std::array<uint8_t, max_text> staged{};
    for (int errors = 0; errors <= k; ++errors) {
        for (int d = -errors; d <= static_cast<int>(n); ++d) {
            const auto slot = diagonal_slot(d);
            auto row = std::max({frontier[slot][static_cast<std::size_t>(errors)] + 1,
                                 frontier[slot - 1][static_cast<std::size_t>(errors)],
                                 frontier[slot + 1][static_cast<std::size_t>(errors)] + 1});
            row = std::min(row, raw_m);
            while (row < raw_m) {
                const auto text_index = row + d;
                if (text_index < 0 || text_index >= raw_n ||
                    pattern[row] != text[text_index]) break;
                ++row;
            }
            frontier[slot][static_cast<std::size_t>(errors + 1)] = row;
            if (row == raw_m) {
                const auto endpoint = d + static_cast<int>(raw_m);
                if (endpoint >= 1 && endpoint <= raw_n)
                    staged[static_cast<std::size_t>(endpoint - 1)] = 1;
            }
        }
    }
    std::copy_n(staged.begin(), n, output);
    return static_cast<int64_t>(n);
}
