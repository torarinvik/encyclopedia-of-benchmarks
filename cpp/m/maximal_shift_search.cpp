#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_text = 4096;
constexpr int max_pattern = 128;
constexpr std::size_t max_input = 4227;
constexpr int alphabet = 4;

int match_shift(const std::array<std::uint8_t, max_pattern>& pattern, int m,
                const std::array<int, max_pattern + 1>& order_loc,
                const std::array<int, max_pattern + 1>& order_symbol,
                int prefix_length, int shift) {
    while (shift < m) {
        int order_index = prefix_length - 1;
        while (order_index >= 0) {
            const int pattern_index = order_loc[order_index] - shift;
            if (pattern_index >= 0 && order_symbol[order_index] != pattern[pattern_index]) break;
            --order_index;
        }
        if (order_index < 0) break;
        ++shift;
    }
    return shift;
}
}

extern "C" std::int64_t maximal_shift_search(const std::int64_t* input,
                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const std::int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > max_text || m64 < 1 || m64 > max_pattern) return -1;
    const int n = static_cast<int>(n64), m = static_cast<int>(m64);
    if (length != static_cast<std::size_t>(2 + n + m)) return -1;
    std::array<std::uint8_t, max_text> text{};
    std::array<std::uint8_t, max_pattern> pattern{};
    for (int q = 0; q < n; ++q) {
        const auto value = input[2 + q];
        if (value < 0 || value >= alphabet) return -1;
        text[static_cast<std::size_t>(q)] = static_cast<std::uint8_t>(value);
    }
    for (int q = 0; q < m; ++q) {
        const auto value = input[2 + n + q];
        if (value < 0 || value >= alphabet) return -1;
        pattern[static_cast<std::size_t>(q)] = static_cast<std::uint8_t>(value);
    }
    if (n < m) return 0;

    std::array<int, max_pattern> leading_shift{};
    std::array<int, max_pattern + 1> order_loc{};
    std::array<int, max_pattern + 1> order_symbol{};
    std::array<int, alphabet> quick_shift{};
    std::array<int, max_pattern + 1> adapted_shift{};
    for (int i = 0; i < m; ++i) {
        int previous = i - 1;
        while (previous >= 0 && pattern[static_cast<std::size_t>(previous)] != pattern[static_cast<std::size_t>(i)]) --previous;
        leading_shift[static_cast<std::size_t>(i)] = i - previous;
        int position = i;
        while (position > 0) {
            const int prior_loc = order_loc[static_cast<std::size_t>(position - 1)];
            if (leading_shift[static_cast<std::size_t>(prior_loc)] > leading_shift[static_cast<std::size_t>(i)] ||
                (leading_shift[static_cast<std::size_t>(prior_loc)] == leading_shift[static_cast<std::size_t>(i)] && prior_loc > i)) break;
            order_loc[static_cast<std::size_t>(position)] = prior_loc;
            --position;
        }
        order_loc[static_cast<std::size_t>(position)] = i;
    }
    for (int i = 0; i < m; ++i)
        order_symbol[static_cast<std::size_t>(i)] = pattern[static_cast<std::size_t>(order_loc[static_cast<std::size_t>(i)])];
    order_loc[static_cast<std::size_t>(m)] = m;
    order_symbol[static_cast<std::size_t>(m)] = -1;

    quick_shift.fill(m + 1);
    for (int i = 0; i < m; ++i) quick_shift[pattern[static_cast<std::size_t>(i)]] = m - i;
    int shift = 1;
    adapted_shift[0] = 1;
    for (int prefix_length = 1; prefix_length <= m; ++prefix_length) {
        shift = match_shift(pattern, m, order_loc, order_symbol, prefix_length, shift);
        adapted_shift[static_cast<std::size_t>(prefix_length)] = shift;
    }
    for (int prefix_length = 0; prefix_length <= m; ++prefix_length) {
        shift = adapted_shift[static_cast<std::size_t>(prefix_length)];
        while (shift < m) {
            const int pattern_index = order_loc[static_cast<std::size_t>(prefix_length)] - shift;
            if (pattern_index < 0 || order_symbol[static_cast<std::size_t>(prefix_length)] != pattern[static_cast<std::size_t>(pattern_index)]) break;
            ++shift;
            shift = match_shift(pattern, m, order_loc, order_symbol, prefix_length, shift);
        }
        adapted_shift[static_cast<std::size_t>(prefix_length)] = shift;
    }

    std::int64_t count = 0, offset_sum = 0, offset_xor = 0;
    int start = 0;
    while (start <= n - m) {
        int compared = 0;
        while (compared < m && order_symbol[static_cast<std::size_t>(compared)] ==
               text[static_cast<std::size_t>(start + order_loc[static_cast<std::size_t>(compared)])]) ++compared;
        if (compared == m) { ++count; offset_sum += start; offset_xor ^= start; }
        const int lookahead = start + m;
        if (lookahead >= n) break;
        start += std::max(adapted_shift[static_cast<std::size_t>(compared)],
                          quick_shift[text[static_cast<std::size_t>(lookahead)]]);
    }
    const std::uint64_t packed = (static_cast<std::uint64_t>(count) << 36) |
                                 (static_cast<std::uint64_t>(offset_sum) << 12) |
                                 static_cast<std::uint64_t>(offset_xor);
    return static_cast<std::int64_t>(packed);
}
