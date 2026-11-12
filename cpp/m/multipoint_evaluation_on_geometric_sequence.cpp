#include <array>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 8, max_m = 8, ntt_size = 32, max_input = 12;
using Transform = std::array<std::int64_t, ntt_size>;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

void ntt(Transform& values, bool inverse) {
    std::size_t j = 0;
    for (std::size_t i = 1; i < ntt_size; ++i) {
        std::size_t bit = ntt_size / 2;
        while ((j & bit) != 0) { j ^= bit; bit >>= 1; }
        j ^= bit;
        if (i < j) std::swap(values[i], values[j]);
    }
    for (std::size_t block = 2; block <= ntt_size; block <<= 1) {
        auto root = mod_pow(3, (modulus - 1) / static_cast<std::int64_t>(block));
        if (inverse) root = mod_pow(root, modulus - 2);
        const auto half = block / 2;
        for (std::size_t start = 0; start < ntt_size; start += block) {
            std::int64_t factor = 1;
            for (std::size_t offset = 0; offset < half; ++offset) {
                const auto even = values[start + offset];
                const auto odd = values[start + offset + half] * factor % modulus;
                values[start + offset] = (even + odd) % modulus;
                values[start + offset + half] = (even - odd + modulus) % modulus;
                factor = factor * root % modulus;
            }
        }
    }
    if (inverse) {
        const auto scale = mod_pow(static_cast<std::int64_t>(ntt_size), modulus - 2);
        for (auto& value : values) value = value * scale % modulus;
    }
}

std::int64_t evaluate(const std::int64_t* coefficients, std::size_t count, std::int64_t x) {
    std::int64_t value = 0;
    for (std::size_t i = count; i > 0; --i) value = (value * x + coefficients[i - 1]) % modulus;
    return value;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t multipoint_evaluation_on_geometric_sequence(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 5 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    const auto start = input[2];
    const auto ratio = input[3];
    if (length != n + 4 || start < 0 || start >= modulus || ratio < 0 || ratio >= modulus) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[4 + i] < 0 || input[4 + i] >= modulus) return -1;
    const auto bytes = 8 * m;
    if (output == nullptr || capacity < bytes) return -2;
    if (start == 0) {
        for (std::size_t i = 0; i < m; ++i) store_le(output, 8 * i, input[4]);
        return static_cast<std::int64_t>(bytes);
    }
    if (ratio == 0) {
        store_le(output, 0, evaluate(input + 4, n, start));
        for (std::size_t i = 1; i < m; ++i) store_le(output, 8 * i, input[4]);
        return static_cast<std::int64_t>(bytes);
    }

    Transform left{}, right{};
    const auto inverse_ratio = mod_pow(ratio, modulus - 2);
    std::int64_t start_power = 1, inverse_chirp = 1, inverse_ratio_power = 1;
    for (std::size_t degree = 0; degree < n; ++degree) {
        left[n - 1 - degree] = input[4 + degree] * start_power % modulus * inverse_chirp % modulus;
        start_power = start_power * start % modulus;
        inverse_chirp = inverse_chirp * inverse_ratio_power % modulus;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % modulus;
    }
    std::int64_t chirp = 1, ratio_power = 1;
    for (std::size_t index = 0; index < n + m - 1; ++index) {
        right[index] = chirp;
        chirp = chirp * ratio_power % modulus;
        ratio_power = ratio_power * ratio % modulus;
    }
    ntt(left, false);
    ntt(right, false);
    for (std::size_t i = 0; i < ntt_size; ++i) left[i] = left[i] * right[i] % modulus;
    ntt(left, true);
    inverse_chirp = 1;
    inverse_ratio_power = 1;
    for (std::size_t i = 0; i < m; ++i) {
        store_le(output, 8 * i, left[n - 1 + i] * inverse_chirp % modulus);
        inverse_chirp = inverse_chirp * inverse_ratio_power % modulus;
        inverse_ratio_power = inverse_ratio_power * inverse_ratio % modulus;
    }
    return static_cast<std::int64_t>(bytes);
}
