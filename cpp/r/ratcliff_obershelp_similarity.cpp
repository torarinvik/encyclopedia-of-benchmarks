#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT = 32;
constexpr std::size_t MAX_INPUT_LENGTH = 67;

std::int64_t longest_match(const std::int64_t* input, std::size_t first_base,
                           std::size_t second_base, std::size_t a0,
                           std::size_t a1, std::size_t b0, std::size_t b1) noexcept {
    std::int64_t dp[MAX_TEXT + 1]{};
    std::size_t best_length = 0, best_a = 0, best_b = 0;
    for (std::size_t i = a0; i < a1; ++i) {
        std::int64_t diagonal = 0;
        for (std::size_t column = 1; column <= b1 - b0; ++column) {
            const auto old = dp[column];
            const auto j = b0 + column - 1;
            if (input[first_base + i] == input[second_base + j]) {
                const auto current = static_cast<std::size_t>(diagonal + 1);
                dp[column] = static_cast<std::int64_t>(current);
                if (current > best_length) {
                    best_length = current;
                    best_a = i + 1 - current;
                    best_b = j + 1 - current;
                }
            } else dp[column] = 0;
            diagonal = old;
        }
    }
    return static_cast<std::int64_t>(best_length * 4096 + best_a * 64 + best_b);
}

std::int64_t matched_characters(const std::int64_t* input,
                               std::size_t first_base, std::size_t second_base,
                               std::size_t a0, std::size_t a1,
                               std::size_t b0, std::size_t b1) noexcept {
    if (a0 >= a1 || b0 >= b1) return 0;
    const auto packed = longest_match(input, first_base, second_base, a0, a1, b0, b1);
    const auto block = static_cast<std::size_t>(packed / 4096);
    if (block == 0) return 0;
    const auto rest = static_cast<std::size_t>(packed % 4096);
    const auto a = rest / 64, b = rest % 64;
    return static_cast<std::int64_t>(block)
        + matched_characters(input, first_base, second_base, a0, a, b0, b)
        + matched_characters(input, first_base, second_base, a + block, a1,
                             b + block, b1);
}
} // namespace

extern "C" std::int64_t ratcliff_obershelp_similarity(const std::int64_t* input,
                                                       std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto first_raw = input[0], second_raw = input[1];
    if (first_raw < 0 || first_raw > static_cast<std::int64_t>(MAX_TEXT)
        || second_raw < 0 || second_raw > static_cast<std::int64_t>(MAX_TEXT)) return -1;
    const auto first_length = static_cast<std::size_t>(first_raw);
    const auto second_length = static_cast<std::size_t>(second_raw);
    if (length != 2 + first_length + second_length) return -1;
    for (std::size_t i = 0; i < first_length + second_length; ++i)
        if (input[2 + i] < 1 || input[2 + i] > 127) return -1;
    if (first_length == 0 || second_length == 0) return 0;
    const auto common = matched_characters(input, 2, 2 + first_length,
                                            0, first_length, 0, second_length);
    return (200 * common) / static_cast<std::int64_t>(first_length + second_length);
}
