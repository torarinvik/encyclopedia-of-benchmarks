#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 32;
constexpr std::size_t max_input = 66;
constexpr std::size_t max_blocks = 6;
constexpr std::size_t max_powers = 7;
using Polynomial = std::array<std::int64_t, max_n>;

Polynomial multiply_truncated(const Polynomial& left, const Polynomial& right, std::size_t n) noexcept
{
    Polynomial product{};
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t j = 0; j < n - i; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % modulus;
    return product;
}

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t brent_kung_fps_composition(const std::int64_t* input,
                                                    std::size_t length,
                                                    std::uint8_t* output,
                                                    std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < 0 || input[i + 1] >= modulus) return -1;
    if (input[1 + n] != 0) return -1;
    const auto bytes = 8 * n;
    if (output == nullptr || capacity < bytes) return -2;

    std::size_t block_size = 1;
    while (block_size * block_size < n) ++block_size;
    const auto block_count = (n + block_size - 1) / block_size;
    std::array<Polynomial, max_powers> powers{};
    std::array<Polynomial, max_blocks> blocks{};
    powers[0][0] = 1;
    const Polynomial inner = [&] {
        Polynomial value{};
        for (std::size_t i = 0; i < n; ++i) value[i] = input[1 + n + i];
        return value;
    }();
    for (std::size_t exponent = 1; exponent <= block_size; ++exponent)
        powers[exponent] = multiply_truncated(powers[exponent - 1], inner, n);
    for (std::size_t block = 0; block < block_count; ++block) {
        for (std::size_t offset = 0; offset < block_size; ++offset) {
            const auto coefficient_index = block * block_size + offset;
            if (coefficient_index >= n) break;
            const auto coefficient = input[1 + coefficient_index];
            for (std::size_t degree = 0; degree < n; ++degree)
                blocks[block][degree] =
                    (blocks[block][degree] + coefficient * powers[offset][degree]) % modulus;
        }
    }
    Polynomial composed = blocks[block_count - 1];
    for (std::size_t block = block_count - 1; block > 0; --block) {
        composed = multiply_truncated(composed, powers[block_size], n);
        for (std::size_t degree = 0; degree < n; ++degree)
            composed[degree] = (composed[degree] + blocks[block - 1][degree]) % modulus;
    }
    for (std::size_t degree = 0; degree < n; ++degree) store_le(output, 8 * degree, composed[degree]);
    return static_cast<std::int64_t>(bytes);
}
