#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;

std::int64_t inverse(std::int64_t a, std::int64_t m) {
    std::int64_t old_r = a, r = m;
    std::int64_t old_s = 1, s = 0;
    while (r != 0) {
        const std::int64_t quotient = old_r / r;
        const std::int64_t next_r = old_r - quotient * r;
        const std::int64_t next_s = old_s - quotient * s;
        old_r = r; r = next_r;
        old_s = s; s = next_s;
    }
    return old_r == 1 ? (old_s + m) % m : -1;
}
}

extern "C" std::int64_t ncr_modulo_p(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return invalid_result;
    const std::int64_t size = values[0], p = values[1], n = values[2], r = values[3];
    if (size < 0 || size > 64 || p < 2 || p > 1009 || n < 0 || n > size ||
        r < 0 || r > 64) return invalid_result;

    std::int64_t fac[65];
    fac[0] = 1;
    for (std::int64_t i = 1; i <= size; ++i) fac[i] = (fac[i - 1] * i) % p;
    if (r > n) return 0;
    if (r == 1) return n % p;
    if (r == 0 || r == n) return 1;
    const std::int64_t denominator = (fac[r] * fac[n - r]) % p;
    const std::int64_t denominator_inv = inverse(denominator, p);
    if (denominator_inv < 0) return -1;
    return (fac[n] * denominator_inv) % p;
}
