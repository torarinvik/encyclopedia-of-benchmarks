#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 16;
constexpr std::size_t max_triangle = max_n * (max_n + 1) / 2;
constexpr std::size_t max_input_length = 2 + max_triangle + max_n * max_n;
constexpr std::int64_t max_value = 1000000;
constexpr std::size_t max_rounds = 32;

bool bounded_value(std::int64_t value) {
    return value >= -max_value && value <= max_value;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t tsvc_s141_packed_symmetric_update(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0], rounds_raw = input[1];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n) ||
        rounds_raw < 1 || rounds_raw > static_cast<std::int64_t>(max_rounds)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    const std::size_t triangle = n * (n + 1) / 2;
    const std::size_t matrix_start = 2 + triangle;
    if (length != matrix_start + n * n) return -1;

    std::int64_t packed[max_triangle]{};
    for (std::size_t p = 0; p < triangle; ++p) {
        packed[p] = input[2 + p];
        if (!bounded_value(packed[p])) return -1;
    }
    for (std::size_t p = 0; p < n * n; ++p)
        if (!bounded_value(input[matrix_start + p])) return -1;
    if (output == nullptr || output_capacity < 8 * triangle) return -2;

    for (std::size_t round = 0; round < static_cast<std::size_t>(rounds_raw); ++round) {
        for (std::size_t i = 0; i < n; ++i) {
            for (std::size_t j = i; j < n; ++j) {
                const std::size_t k = j * (j + 1) / 2 + i;
                packed[k] += input[matrix_start + j * n + i];
            }
        }
    }
    for (std::size_t p = 0; p < triangle; ++p) store_i64_le(output, 8 * p, packed[p]);
    return static_cast<std::int64_t>(triangle);
}
