// Clean-room port of TSVC s353; provenance and rights are in the package README.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 20;
constexpr std::size_t kMaxInputLength = 2 + 3 * kMaxN;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s353_unrolled_sparse_saxpy(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 17 || length > kMaxInputLength) return -1;
    if (input[0] < 5 || input[0] > static_cast<std::int64_t>(kMaxN) || input[0] % 5 != 0) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 2 + 3 * n) return -1;
    const auto alpha = input[1];
    if (alpha < -8 || alpha > 8) return -1;
    std::int64_t a[kMaxN], b[kMaxN], indices[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        indices[i] = input[2 + 2 * n + i];
        if (a[i] < -1'000'000 || a[i] > 1'000'000 || b[i] < -1'000'000 || b[i] > 1'000'000 ||
            indices[i] < 0 || indices[i] >= static_cast<std::int64_t>(n)) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    for (std::size_t i = 0; i < n; i += 5) {
        a[i] += alpha * b[static_cast<std::size_t>(indices[i])];
        a[i + 1] += alpha * b[static_cast<std::size_t>(indices[i + 1])];
        a[i + 2] += alpha * b[static_cast<std::size_t>(indices[i + 2])];
        a[i + 3] += alpha * b[static_cast<std::size_t>(indices[i + 3])];
        a[i + 4] += alpha * b[static_cast<std::size_t>(indices[i + 4])];
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
