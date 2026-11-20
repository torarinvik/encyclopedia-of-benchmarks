#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t kMod = 998244353;
constexpr std::size_t kMaxStates = 7;

std::int64_t pow_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % kMod;
        base = base * base % kMod;
        exponent >>= 1;
    }
    return result;
}

int find_state(const std::int64_t (&codes)[kMaxStates],
               const std::int64_t (&lengths)[kMaxStates], std::size_t count,
               std::int64_t code, std::int64_t length) {
    for (std::size_t i = 0; i < count; ++i)
        if (codes[i] == code && lengths[i] == length) return static_cast<int>(i);
    return -1;
}

std::int64_t solve(std::int64_t word_length, std::int64_t first, std::int64_t second) {
    std::int64_t codes[kMaxStates]{};
    std::int64_t lengths[kMaxStates]{};
    std::size_t state_count = 1;
    const std::int64_t patterns[2] = {first, second};
    for (std::int64_t prefix_length = 1; prefix_length < word_length; ++prefix_length) {
        for (std::size_t which = 0; which < 2; ++which) {
            const auto code = patterns[which] >> (word_length - prefix_length);
            if (find_state(codes, lengths, state_count, code, prefix_length) < 0) {
                codes[state_count] = code;
                lengths[state_count] = prefix_length;
                ++state_count;
            }
        }
    }

    std::int64_t matrix[kMaxStates][kMaxStates + 1]{};
    for (std::size_t row = 0; row < state_count; ++row) {
        for (std::size_t column = 0; column < state_count; ++column)
            matrix[row][column] = row == column ? 2 : 0;
        for (std::int64_t bit = 0; bit <= 1; ++bit) {
            const auto candidate = (codes[row] << 1) | bit;
            const auto candidate_length = lengths[row] + 1;
            if (candidate_length == word_length && candidate == first) {
                ++matrix[row][state_count];
                continue;
            }
            if (candidate_length == word_length && candidate == second) continue;
            std::int64_t suffix_length = candidate_length;
            if (suffix_length > word_length - 1) suffix_length = word_length - 1;
            int destination = -1;
            for (; suffix_length >= 0 && destination < 0; --suffix_length) {
                const auto suffix_mask = (std::int64_t{1} << suffix_length) - 1;
                destination = find_state(codes, lengths, state_count,
                                         candidate & suffix_mask, suffix_length);
            }
            if (destination < 0) destination = 0;
            matrix[row][destination] = (matrix[row][destination] - 1 + kMod) % kMod;
        }
    }

    for (std::size_t column = 0; column < state_count; ++column) {
        std::size_t pivot = column;
        while (pivot < state_count && matrix[pivot][column] == 0) ++pivot;
        if (pivot == state_count) return -1;
        if (pivot != column)
            for (std::size_t j = 0; j <= state_count; ++j)
                std::swap(matrix[column][j], matrix[pivot][j]);
        const auto inverse = pow_mod(matrix[column][column], kMod - 2);
        for (std::size_t j = column; j <= state_count; ++j)
            matrix[column][j] = matrix[column][j] * inverse % kMod;
        for (std::size_t row = 0; row < state_count; ++row) {
            if (row == column) continue;
            const auto factor = matrix[row][column];
            for (std::size_t j = column; j <= state_count; ++j)
                matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] % kMod + kMod) % kMod;
        }
    }
    return matrix[0][state_count];
}
} // namespace

extern "C" std::int64_t penney_game_pattern_probability(const std::int64_t *input,
                                                         std::size_t length) {
    if (input == nullptr || length != 3) return -1;
    const auto word_length = input[0];
    if (word_length < 1 || word_length > 4) return -1;
    const auto limit = std::int64_t{1} << word_length;
    const auto first = input[1], second = input[2];
    if (first < 0 || second < 0 || first >= limit || second >= limit || first == second)
        return -1;
    return solve(word_length, first, second);
}
