// Clean-room port of TSVC s126; provenance and rights are in the package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 6;
constexpr std::size_t kMaxCells = kMaxN * kMaxN;
constexpr std::size_t kMaxInputLength = 1 + 3 * kMaxCells;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s126_matrix_column_recurrence(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 13 || length > kMaxInputLength) return -1;
    if (input[0] < 2 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    std::int64_t coefficients[kMaxCells], c_matrix[kMaxCells], b_matrix[kMaxCells];
    for (std::size_t i = 0; i < cells; ++i) {
        coefficients[i] = input[1 + i];
        c_matrix[i] = input[1 + cells + i];
        b_matrix[i] = input[1 + 2 * cells + i];
        if (coefficients[i] < -100 || coefficients[i] > 100 ||
            c_matrix[i] < -100 || c_matrix[i] > 100 || b_matrix[i] < -100 || b_matrix[i] > 100) return -1;
    }
    const auto output_bytes = 8 * cells;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t k = 1;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 1; j < n; ++j) {
            const auto target = j * n + i;
            b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target];
            ++k;
        }
        ++k;
    }
    for (std::size_t i = 0; i < cells; ++i) store_i64_le(output, 8 * i, b_matrix[i]);
    return static_cast<std::int64_t>(cells);
}
