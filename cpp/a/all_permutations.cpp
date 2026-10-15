// Emit permutations in depth-first input-index order; equal values keep multiplicity.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 6;
constexpr std::size_t bytes_per_value = 4;

void store_i32_le(std::uint8_t *output, std::size_t position, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

void generate(const std::int32_t *values, std::size_t n, std::size_t depth,
              std::int32_t *current, bool *used, std::uint8_t *output,
              std::size_t &result_count) {
    if (depth == n) {
        const auto row_start = result_count * n * bytes_per_value;
        for (std::size_t index = 0; index < n; ++index)
            store_i32_le(output, row_start + index * bytes_per_value, current[index]);
        ++result_count;
        return;
    }
    for (std::size_t index = 0; index < n; ++index) {
        if (used[index]) continue;
        current[depth] = values[index];
        used[index] = true;
        generate(values, n, depth + 1, current, used, output, result_count);
        used[index] = false;
    }
}
}

extern "C" std::int64_t all_permutations(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_length + 1) return -1;
    const auto n_value = input[0];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_length) ||
        length != static_cast<std::size_t>(n_value) + 1) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::int32_t values[max_length];
    for (std::size_t index = 0; index < n; ++index) {
        const auto value = input[index + 1];
        if (value < std::numeric_limits<std::int32_t>::min() || value > std::numeric_limits<std::int32_t>::max()) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }
    std::size_t permutation_count = 1;
    for (std::size_t factor = 2; factor <= n; ++factor) permutation_count *= factor;
    const auto required = permutation_count * n * bytes_per_value;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;
    std::int32_t current[max_length];
    bool used[max_length]{};
    std::size_t result_count = 0;
    generate(values, n, 0, current, used, output, result_count);
    return static_cast<std::int64_t>(result_count);
}
