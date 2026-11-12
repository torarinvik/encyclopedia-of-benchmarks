// Clean-room bounded implementation of the Library Checker sequence-counting task.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64, max_m = 64, max_input_length = 130;
constexpr std::int64_t mod = 998244353;
}

extern "C" std::int64_t number_of_increasing_sequences_between_two_sequences(
    const std::int64_t *input, std::size_t length) {
    if (!input || length < 4 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + 2 * n) return -1;
    std::array<std::int64_t, max_n> lower{}, upper{};
    for (std::size_t i = 0; i < n; ++i) {
        lower[i] = input[2 + i];
        upper[i] = input[2 + n + i];
        if (lower[i] < 0 || lower[i] >= upper[i] || upper[i] > static_cast<std::int64_t>(m)) return -1;
    }
    std::array<std::int64_t, max_m> previous{}, current{};
    for (std::size_t value = static_cast<std::size_t>(lower[0]); value < static_cast<std::size_t>(upper[0]); ++value)
        previous[value] = 1;
    for (std::size_t position = 1; position < n; ++position) {
        std::int64_t prefix = 0;
        for (std::size_t value = 0; value < m; ++value) {
            prefix += previous[value];
            if (prefix >= mod) prefix -= mod;
            current[value] = lower[position] <= static_cast<std::int64_t>(value) &&
                             static_cast<std::int64_t>(value) < upper[position] ? prefix : 0;
        }
        previous.swap(current);
    }
    std::int64_t answer = 0;
    for (std::size_t value = 0; value < m; ++value) {
        answer += previous[value];
        if (answer >= mod) answer -= mod;
    }
    return answer;
}
