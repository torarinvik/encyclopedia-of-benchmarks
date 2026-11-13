#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 1000000007;

std::int64_t power_mod(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t turnstile_one_sparse_fingerprint_recovery(
    const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > 260) return -1;
    const auto n = input[0], q = input[1], base = input[2];
    if (n < 1 || n > 64 || q < 0 || q > 128 || base < 1 || base >= modulus ||
        length != static_cast<std::size_t>(3 + 2 * q)) return -1;
    std::int64_t mass = 0, weighted = 0, fingerprint = 0;
    for (std::int64_t i = 0; i < q; ++i) {
        const auto index = input[3 + 2 * i], delta = input[4 + 2 * i];
        if (index < 0 || index >= n || delta < -1000 || delta > 1000) return -1;
        mass += delta;
        weighted += delta * index;
        fingerprint = (fingerprint + delta * power_mod(base, index)) % modulus;
        if (fingerprint < 0) fingerprint += modulus;
    }
    if (mass == 0 || weighted % mass != 0) return 0;
    const auto index = weighted / mass;
    if (index < 0 || index >= n) return 0;
    auto expected = mass * power_mod(base, index) % modulus;
    if (expected < 0) expected += modulus;
    return fingerprint == expected ? index + 1 : 0;
}
