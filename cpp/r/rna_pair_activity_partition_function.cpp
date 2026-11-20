#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_sequence_length = 16;
constexpr std::size_t max_parseable_length = 122;

std::size_t pair_input_index(std::size_t n, std::size_t left, std::size_t right) {
    const std::size_t preceding = left * (2 * n - left - 1) / 2;
    return 1 + preceding + (right - left - 1);
}
}

extern "C" std::int64_t rna_pair_activity_partition_function(
    const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_sequence_length)) return -1;
    const std::size_t n = static_cast<std::size_t>(input[0]);
    const std::size_t expected_length = n == 0 ? 1 : 1 + n * (n - 1) / 2;
    if (length != expected_length) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] > 3) return -1;
    if (n == 0) return 1;

    std::array<std::array<std::int64_t, max_sequence_length>, max_sequence_length> table{};
    for (std::size_t span = 1; span <= n; ++span) {
        for (std::size_t left = 0; left + span <= n; ++left) {
            const std::size_t right = left + span - 1;
            std::int64_t total = left == right ? 1 : table[left][right - 1];
            for (std::size_t partner = left; partner < right; ++partner) {
                const auto activity = input[pair_input_index(n, partner, right)];
                const std::int64_t before = partner == left ? 1 : table[left][partner - 1];
                const std::int64_t inside = partner + 1 >= right ? 1 : table[partner + 1][right - 1];
                total += before * inside * activity;
            }
            table[left][right] = total;
        }
    }
    return table[0][n - 1];
}
