#include <cstddef>
#include <cstdint>

extern "C" std::int64_t longest_common_increasing_subsequence(const std::int64_t* input,
                                                               std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 67) return -1;
    const auto n_value = input[0];
    const auto m_value = input[1];
    if (n_value < 0 || n_value > 32 || m_value < 0 || m_value > 32) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto m = static_cast<std::size_t>(m_value);
    if (length != 2 + n + m) return -1;
    for (std::size_t index = 0; index < n + m; ++index) {
        if (input[2 + index] < -16 || input[2 + index] > 16) return -1;
    }

    std::int64_t ending_at[32]{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[2 + i];
        std::int64_t best_smaller = 0;
        for (std::size_t j = 0; j < m; ++j) {
            const auto other = input[2 + n + j];
            if (value > other && ending_at[j] > best_smaller) {
                best_smaller = ending_at[j];
            } else if (value == other && best_smaller + 1 > ending_at[j]) {
                ending_at[j] = best_smaller + 1;
            }
        }
    }
    std::int64_t answer = 0;
    for (std::size_t j = 0; j < m; ++j) if (ending_at[j] > answer) answer = ending_at[j];
    return answer;
}
