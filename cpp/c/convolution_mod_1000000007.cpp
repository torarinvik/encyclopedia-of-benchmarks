#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t kMod = 1000000007;
constexpr std::array<std::int64_t, 3> kPrimes{998244353, 1004535809, 469762049};
constexpr std::size_t kMaxLength = 64;
constexpr std::size_t kNttSize = 128;
constexpr std::size_t kMaxResult = 2 * kMaxLength - 1;
constexpr std::size_t kMaxInput = 2 + 2 * kMaxLength;

std::int64_t power_mod(std::int64_t base, std::int64_t exponent, std::int64_t mod) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % mod;
        base = base * base % mod;
        exponent >>= 1;
    }
    return result;
}

void transform(std::array<std::int64_t, kNttSize>& values, std::size_t n,
               std::int64_t mod, bool inverse) {
    for (std::size_t i = 1, j = 0; i < n; ++i) {
        std::size_t bit = n >> 1;
        for (; (j & bit) != 0; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(values[i], values[j]);
    }
    for (std::size_t stage = 2; stage <= n; stage <<= 1) {
        auto root = power_mod(3, (mod - 1) / static_cast<std::int64_t>(stage), mod);
        if (inverse) root = power_mod(root, mod - 2, mod);
        for (std::size_t start = 0; start < n; start += stage) {
            std::int64_t factor = 1;
            for (std::size_t offset = 0; offset < stage / 2; ++offset) {
                const auto left = values[start + offset];
                const auto right = values[start + offset + stage / 2] * factor % mod;
                values[start + offset] = (left + right) % mod;
                values[start + offset + stage / 2] = (left - right + mod) % mod;
                factor = factor * root % mod;
            }
        }
    }
    if (inverse) {
        const auto scale = power_mod(static_cast<std::int64_t>(n), mod - 2, mod);
        for (std::size_t i = 0; i < n; ++i) values[i] = values[i] * scale % mod;
    }
}

std::array<std::int64_t, kMaxResult> residues(const std::int64_t* input,
    std::size_t n, std::size_t m, std::size_t transform_size,
    std::size_t result_size, std::int64_t mod) {
    std::array<std::int64_t, kNttSize> a{};
    std::array<std::int64_t, kNttSize> b{};
    for (std::size_t i = 0; i < n; ++i) a[i] = input[2 + i] % mod;
    for (std::size_t i = 0; i < m; ++i) b[i] = input[2 + n + i] % mod;
    transform(a, transform_size, mod, false);
    transform(b, transform_size, mod, false);
    for (std::size_t i = 0; i < transform_size; ++i) a[i] = a[i] * b[i] % mod;
    transform(a, transform_size, mod, true);
    std::array<std::int64_t, kMaxResult> result{};
    for (std::size_t i = 0; i < result_size; ++i) result[i] = a[i];
    return result;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}  // namespace

extern "C" std::int64_t convolution_mod_1000000007(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    if (input[0] < 1 || input[0] > 64 || input[1] < 1 || input[1] > 64) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= kMod) return -1;
    const auto result_size = n + m - 1;
    std::size_t transform_size = 1;
    while (transform_size < result_size) transform_size <<= 1;
    const auto bytes = 8 * result_size;
    if (output == nullptr || capacity < bytes) return -2;

    const auto r1 = residues(input, n, m, transform_size, result_size, kPrimes[0]);
    const auto r2 = residues(input, n, m, transform_size, result_size, kPrimes[1]);
    const auto r3 = residues(input, n, m, transform_size, result_size, kPrimes[2]);
    const auto inv1 = power_mod(kPrimes[0] % kPrimes[1], kPrimes[1] - 2, kPrimes[1]);
    const auto p12mod3 = kPrimes[0] % kPrimes[2] * (kPrimes[1] % kPrimes[2]) % kPrimes[2];
    const auto inv12 = power_mod(p12mod3, kPrimes[2] - 2, kPrimes[2]);
    const auto p1mod = kPrimes[0] % kMod;
    const auto p12mod = p1mod * (kPrimes[1] % kMod) % kMod;
    for (std::size_t i = 0; i < result_size; ++i) {
        const auto t1 = ((r2[i] - r1[i] % kPrimes[1] + kPrimes[1]) % kPrimes[1]) * inv1 % kPrimes[1];
        const auto x12 = (r1[i] % kPrimes[2] + (kPrimes[0] % kPrimes[2]) * (t1 % kPrimes[2])) % kPrimes[2];
        const auto t2 = ((r3[i] - x12 + kPrimes[2]) % kPrimes[2]) * inv12 % kPrimes[2];
        const auto value = (r1[i] + p1mod * (t1 % kMod) + p12mod * (t2 % kMod)) % kMod;
        store_i64_le(output, 8 * i, value);
    }
    return static_cast<std::int64_t>(bytes);
}
