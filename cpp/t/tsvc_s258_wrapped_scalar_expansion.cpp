// Clean-room port of TSVC s258; see package README for provenance and rights.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t tsvc_s258_wrapped_scalar_expansion(
    const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t kMaxN = 64;
    if (input == nullptr || length < 5 || length > 257) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * n) return -1;
    std::int64_t a[kMaxN], c[kMaxN], d[kMaxN], aa0[kMaxN], b[kMaxN], e[kMaxN];
    const auto c_start = 1 + n;
    const auto d_start = 1 + 2 * n;
    const auto aa_start = 1 + 3 * n;
    for (std::size_t i = 0; i < n; ++i) {
        a[i] = input[1 + i];
        c[i] = input[c_start + i];
        d[i] = input[d_start + i];
        aa0[i] = input[aa_start + i];
        if (a[i] < 0 || a[i] > 2 || c[i] < 0 || c[i] > 2 ||
            d[i] < 0 || d[i] > 2 || aa0[i] < 0 || aa0[i] > 2) return -1;
    }
    std::int64_t s = 0;
    for (std::size_t i = 0; i < n; ++i) {
        if (a[i] > 0) s = d[i] * d[i];
        b[i] = s * c[i] + d[i];
        e[i] = (s + 1) * aa0[i];
    }
    std::int64_t sum_b = 0, sum_e = 0;
    for (std::size_t i = 0; i < n; ++i) sum_b += b[i];
    for (std::size_t i = 0; i < n; ++i) sum_e += e[i];
    return sum_b + sum_e;
}
