// Emit unique ASCII permutations in sorted depth-first order.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 6;

void generate(const std::int32_t *values, std::size_t n, std::size_t depth,
              std::int32_t *current, bool *used, std::uint8_t *output,
              std::size_t &result_count) {
    if (depth == n) {
        const auto row = result_count * n;
        for (std::size_t i = 0; i < n; ++i) output[row + i] = static_cast<std::uint8_t>(current[i]);
        ++result_count;
        return;
    }
    for (std::size_t i = 0; i < n; ++i) {
        if (used[i]) continue;
        if (i > 0 && values[i] == values[i - 1] && !used[i - 1]) continue;
        current[depth] = values[i]; used[i] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[i] = false;
    }
}
}

extern "C" std::int64_t unique_permutation(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (!input || length < 1 || length > max_length + 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_length) || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::int32_t values[max_length];
    for (std::size_t i = 0; i < n; ++i) { if (input[i + 1] < 0 || input[i + 1] > 127) return -1; values[i] = static_cast<std::int32_t>(input[i + 1]); }
    for (std::size_t i = 1; i < n; ++i) { const auto value = values[i]; auto p = i; while (p > 0 && values[p - 1] > value) { values[p] = values[p - 1]; --p; } values[p] = value; }
    std::size_t max_count = 1; for (std::size_t factor = 2; factor <= n; ++factor) max_count *= factor;
    const auto required = max_count * n;
    if (output_capacity < required || (required != 0 && !output)) return -2;
    std::int32_t current[max_length]; bool used[max_length]{}; std::size_t result_count = 0;
    generate(values, n, 0, current, used, output, result_count);
    return static_cast<std::int64_t>(result_count);
}
