#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t kMaxLength = 64;
constexpr std::size_t kMaxNttSize = 128;
constexpr std::size_t kMaxInputLength = 2 + 2 * kMaxLength + 1;
constexpr std::size_t kMaxResultLength = 2 * kMaxLength - 1;
constexpr std::array<std::int64_t, 5> kModuli = {
    998244353, 985661441, 943718401, 935329793, 918552577};
constexpr std::array<std::int64_t, 5> kRoots = {3, 3, 7, 3, 5};

std::int64_t power_mod(std::int64_t base, std::int64_t exponent,
                       std::int64_t modulus) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

void transform(std::array<std::int64_t, kMaxNttSize>& values, std::size_t n,
               std::int64_t modulus, std::int64_t primitive_root, bool inverse) {
    for (std::size_t i = 1, j = 0; i < n; ++i) {
        std::size_t bit = n >> 1;
        for (; (j & bit) != 0; bit >>= 1) j ^= bit;
        j ^= bit;
        if (i < j) std::swap(values[i], values[j]);
    }
    for (std::size_t stage = 2; stage <= n; stage <<= 1) {
        auto root = power_mod(primitive_root, (modulus - 1) / static_cast<std::int64_t>(stage), modulus);
        if (inverse) root = power_mod(root, modulus - 2, modulus);
        for (std::size_t start = 0; start < n; start += stage) {
            std::int64_t factor = 1;
            for (std::size_t offset = 0; offset < stage / 2; ++offset) {
                const auto left = values[start + offset];
                const auto right = values[start + offset + stage / 2] * factor % modulus;
                values[start + offset] = (left + right) % modulus;
                values[start + offset + stage / 2] = (left - right + modulus) % modulus;
                factor = factor * root % modulus;
            }
        }
    }
    if (inverse) {
        const auto scale = power_mod(static_cast<std::int64_t>(n), modulus - 2, modulus);
        for (std::size_t i = 0; i < n; ++i) values[i] = values[i] * scale % modulus;
    }
}

void convolution_residues(const std::int64_t* input, std::size_t n, std::size_t m,
                          std::size_t transform_length, std::int64_t modulus,
                          std::int64_t primitive_root,
                          std::array<std::int64_t, kMaxResultLength>& result) {
    std::array<std::int64_t, kMaxNttSize> a{};
    std::array<std::int64_t, kMaxNttSize> b{};
    for (std::size_t i = 0; i < n; ++i)
        a[i] = static_cast<std::uint64_t>(input[2 + i]) % static_cast<std::uint64_t>(modulus);
    for (std::size_t i = 0; i < m; ++i)
        b[i] = static_cast<std::uint64_t>(input[2 + n + i]) % static_cast<std::uint64_t>(modulus);
    transform(a, transform_length, modulus, primitive_root, false);
    transform(b, transform_length, modulus, primitive_root, false);
    for (std::size_t i = 0; i < transform_length; ++i) a[i] = a[i] * b[i] % modulus;
    transform(a, transform_length, modulus, primitive_root, true);
    for (std::size_t i = 0; i < n + m - 1; ++i) result[i] = a[i];
}

std::int64_t positive_delta(std::int64_t value, std::int64_t partial,
                            std::int64_t modulus) {
    const auto delta = value - partial;
    return delta < 0 ? delta + modulus : delta;
}

void store_u64_le(std::uint8_t* output, std::size_t offset, std::uint64_t value) {
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
} // namespace

extern "C" std::int64_t convolution_mod_2_64(const std::int64_t* input,
                                               std::size_t length,
                                               std::uint8_t* output,
                                               std::size_t capacity) {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const auto n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxLength)
            || m_value < 1 || m_value > static_cast<std::int64_t>(kMaxLength)) return -1;
    const auto n = static_cast<std::size_t>(n_value), m = static_cast<std::size_t>(m_value);
    if (length != 2 + n + m) return -1;

    const auto result_length = n + m - 1;
    std::size_t transform_length = 1;
    while (transform_length < result_length) transform_length <<= 1;
    const auto output_bytes = 8 * result_length;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<std::array<std::int64_t, kMaxResultLength>, 5> residues{};
    for (std::size_t prime = 0; prime < kModuli.size(); ++prime)
        convolution_residues(input, n, m, transform_length, kModuli[prime],
                             kRoots[prime], residues[prime]);

    const auto p0 = kModuli[0], p1 = kModuli[1], p2 = kModuli[2];
    const auto p3 = kModuli[3], p4 = kModuli[4];
    const auto p01_mod_p2 = (p0 % p2) * (p1 % p2) % p2;
    const auto p01_mod_p3 = (p0 % p3) * (p1 % p3) % p3;
    const auto p01_mod_p4 = (p0 % p4) * (p1 % p4) % p4;
    const auto p012_mod_p3 = p01_mod_p3 * (p2 % p3) % p3;
    const auto p012_mod_p4 = p01_mod_p4 * (p2 % p4) % p4;
    const auto p0123_mod_p4 = p012_mod_p4 * (p3 % p4) % p4;
    const auto inv_p0_p1 = power_mod(p0 % p1, p1 - 2, p1);
    const auto inv_p01_p2 = power_mod(p01_mod_p2, p2 - 2, p2);
    const auto inv_p012_p3 = power_mod(p012_mod_p3, p3 - 2, p3);
    const auto inv_p0123_p4 = power_mod(p0123_mod_p4, p4 - 2, p4);

    for (std::size_t index = 0; index < result_length; ++index) {
        const auto t0 = residues[0][index];
        const auto t1 = positive_delta(residues[1][index], t0 % p1, p1) * inv_p0_p1 % p1;
        const auto x01_p2 = (residues[0][index] % p2 + (p0 % p2) * t1) % p2;
        const auto t2 = positive_delta(residues[2][index], x01_p2, p2) * inv_p01_p2 % p2;
        const auto x012_p3 = (residues[0][index] % p3 + (p0 % p3) * t1
                              + p01_mod_p3 * t2) % p3;
        const auto t3 = positive_delta(residues[3][index], x012_p3, p3) * inv_p012_p3 % p3;
        const auto x0123_p4 = (residues[0][index] % p4 + (p0 % p4) * t1
                               + p01_mod_p4 * t2 + p012_mod_p4 * t3) % p4;
        const auto t4 = positive_delta(residues[4][index], x0123_p4, p4) * inv_p0123_p4 % p4;
        const std::uint64_t value = static_cast<std::uint64_t>(t0)
            + static_cast<std::uint64_t>(p0) * static_cast<std::uint64_t>(t1)
            + static_cast<std::uint64_t>(p0) * static_cast<std::uint64_t>(p1) * static_cast<std::uint64_t>(t2)
            + static_cast<std::uint64_t>(p0) * static_cast<std::uint64_t>(p1) * static_cast<std::uint64_t>(p2) * static_cast<std::uint64_t>(t3)
            + static_cast<std::uint64_t>(p0) * static_cast<std::uint64_t>(p1) * static_cast<std::uint64_t>(p2) * static_cast<std::uint64_t>(p3) * static_cast<std::uint64_t>(t4);
        store_u64_le(output, 8 * index, value);
    }
    return static_cast<std::int64_t>(output_bytes);
}
