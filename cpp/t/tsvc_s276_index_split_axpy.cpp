// Clean-room bounded port of TSVC s276; see package README for provenance.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_passes = 8;
constexpr std::size_t max_input_length = 2 + 4 * max_n;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t tsvc_s276_index_split_axpy(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 6 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0], passes_raw = input[1];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n) ||
        passes_raw < 1 || passes_raw > static_cast<std::int64_t>(max_passes)) return -1;
    const auto n = static_cast<std::size_t>(n_raw);
    const auto passes = static_cast<std::size_t>(passes_raw);
    if (length != 2 + 4 * n) return -1;
    for (std::size_t i = 2; i < length; ++i)
        if (input[i] < -2 || input[i] > 2) return -1;
    if (output == nullptr || output_capacity < 8 * n) return -2;

    const std::size_t a_start = 2, b_start = a_start + n;
    const std::size_t c_start = b_start + n, d_start = c_start + n, mid = n / 2;
    std::int64_t a[max_n]{};
    for (std::size_t i = 0; i < n; ++i) a[i] = input[a_start + i];
    for (std::size_t pass = 0; pass < passes; ++pass) {
        for (std::size_t i = 0; i < n; ++i) {
            const std::size_t coefficient_start = i + 1 < mid ? c_start : d_start;
            a[i] += input[b_start + i] * input[coefficient_start + i];
        }
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
