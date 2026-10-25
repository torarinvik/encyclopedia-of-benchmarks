// Clean-room bounded port of TSVC s442; see package README for provenance.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxPasses = 16;
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t tsvc_s442_indexed_square_accumulate(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 8 || length > 386) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(kMaxPasses)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto passes = static_cast<std::size_t>(input[1]);
    if (length != 2 + 6 * n) return -1;
    std::int64_t a[kMaxN], b[kMaxN], c[kMaxN], d[kMaxN], e[kMaxN], selector[kMaxN];
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[2 + i];
        b[i] = input[2 + n + i];
        c[i] = input[2 + 2 * n + i];
        d[i] = input[2 + 3 * n + i];
        e[i] = input[2 + 4 * n + i];
        selector[i] = input[2 + 5 * n + i];
        if (a[i] < -2 || a[i] > 2 || b[i] < -2 || b[i] > 2 ||
            c[i] < -2 || c[i] > 2 || d[i] < -2 || d[i] > 2 ||
            e[i] < -2 || e[i] > 2 || selector[i] < 1 || selector[i] > 4) return -1;
    }
    if (output == nullptr || capacity < 8 * n) return -2;
    for (std::size_t round = 0; round < passes; ++round) {
        for (std::size_t i = 0; i < n; ++i) {
            const auto selected = selector[i] == 1 ? b[i] :
                                  selector[i] == 2 ? c[i] :
                                  selector[i] == 3 ? d[i] : e[i];
            a[i] += selected * selected;
        }
    }
    for (std::size_t i = 0; i < n; ++i) store_i64_le(output, 8 * i, a[i]);
    return static_cast<std::int64_t>(n);
}
