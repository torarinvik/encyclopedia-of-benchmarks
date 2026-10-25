// Clean-room port of TSVC s125; provenance and rights are in the package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 8;
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

extern "C" std::int64_t tsvc_s125_matrix_flattened_fma(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > kMaxInputLength) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    std::int64_t aa[kMaxCells], bb[kMaxCells], cc[kMaxCells], result[kMaxCells];
    for (std::size_t i = 0; i < cells; ++i) {
        aa[i] = input[1 + i];
        bb[i] = input[1 + cells + i];
        cc[i] = input[1 + 2 * cells + i];
        if (aa[i] < -100 || aa[i] > 100 || bb[i] < -100 || bb[i] > 100 ||
            cc[i] < -100 || cc[i] > 100) return -1;
    }
    const auto output_bytes = 8 * cells;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::size_t k = 0;
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            result[k] = aa[k] + bb[k] * cc[k];
            ++k;
        }
    }
    for (std::size_t i = 0; i < cells; ++i) store_i64_le(output, 8 * i, result[i]);
    return static_cast<std::int64_t>(cells);
}
