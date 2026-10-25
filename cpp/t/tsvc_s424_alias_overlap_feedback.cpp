// Clean-room port of TSVC s424; see package README for provenance and rights.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s424_alias_overlap_feedback(
    const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t kMinN = 66;
    constexpr std::size_t kMaxN = 192;
    constexpr std::size_t kXLength = kMaxN + 63;
    if (input == nullptr || length < 130 || length > 256) return -1;
    if (input[0] < static_cast<std::int64_t>(kMinN) ||
        input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 64) return -1;
    std::int64_t a[kMaxN];
    std::int64_t x[kXLength]{};
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        if (a[i] < 0 || a[i] > 10) return -1;
    }
    for (std::size_t i = 0; i < 63; ++i) {
        x[i] = input[1 + n + i];
        if (x[i] < 0 || x[i] > 10) return -1;
    }
    // xx is array+63, so each xx[i+1] store aliases array[i+64].
    for (std::size_t i = 0; i < n - 1; ++i) x[i + 64] = x[i] + a[i];
    std::int64_t checksum = 0;
    for (std::size_t i = 0; i < n; ++i) checksum += x[63 + i];
    return checksum;
}
