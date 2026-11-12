#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998'244'353;
constexpr std::size_t max_n = 8, max_m = 8, leaf_base = 8;
constexpr std::size_t node_capacity = 16, coefficient_capacity = 9, max_input = 18;
using Polynomial = std::array<std::int64_t, coefficient_capacity>;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}

std::size_t trim(const Polynomial& polynomial, std::size_t length) {
    while (length > 1 && polynomial[length - 1] == 0) --length;
    return length;
}

std::size_t multiply(const Polynomial& left, std::size_t left_length,
                     const Polynomial& right, std::size_t right_length,
                     Polynomial& product) {
    const auto length = left_length + right_length - 1;
    product.fill(0);
    for (std::size_t i = 0; i < left_length; ++i)
        for (std::size_t j = 0; j < right_length; ++j)
            product[i + j] = (product[i + j] + left[i] * right[j]) % modulus;
    return length;
}

std::size_t remainder(const Polynomial& dividend, std::size_t dividend_length,
                      const Polynomial& divisor, std::size_t divisor_length,
                      Polynomial& result) {
    result.fill(0);
    if (divisor_length == 1 && divisor[0] == 1) return 1;
    result = dividend;
    auto length = trim(result, dividend_length);
    while (length >= divisor_length) {
        const auto shift = length - divisor_length;
        const auto factor = result[length - 1];
        for (std::size_t degree = 0; degree < divisor_length; ++degree) {
            auto& slot = result[shift + degree];
            slot = (slot - factor * divisor[degree]) % modulus;
            if (slot < 0) slot += modulus;
        }
        length = trim(result, length);
    }
    return length;
}
}

extern "C" std::int64_t multipoint_evaluation(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto m = static_cast<std::size_t>(input[1]);
    if (length != 2 + n + m) return -1;
    for (std::size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= modulus) return -1;
    if (input[1 + n] == 0) return -1;
    const auto bytes = 8 * m;
    if (output == nullptr || capacity < bytes) return -2;

    std::array<Polynomial, node_capacity> products{};
    std::array<Polynomial, node_capacity> remainders{};
    std::array<std::size_t, node_capacity> product_lengths{};
    std::array<std::size_t, node_capacity> remainder_lengths{};
    std::array<std::size_t, node_capacity> starts{};
    std::array<std::size_t, node_capacity> spans{};
    for (std::size_t node = 1; node < node_capacity; ++node) {
        products[node][0] = 1;
        product_lengths[node] = 1;
    }
    for (std::size_t i = 0; i < m; ++i) {
        const auto leaf = leaf_base + i;
        products[leaf][0] = input[2 + n + i] == 0 ? 0 : modulus - input[2 + n + i];
        products[leaf][1] = 1;
        product_lengths[leaf] = 2;
    }
    for (std::size_t node = leaf_base - 1; node > 0; --node)
        product_lengths[node] = multiply(products[2 * node], product_lengths[2 * node],
            products[2 * node + 1], product_lengths[2 * node + 1], products[node]);
    starts[1] = 0;
    spans[1] = leaf_base;
    for (std::size_t node = 1; node < leaf_base; ++node) {
        spans[2 * node] = spans[node] / 2;
        spans[2 * node + 1] = spans[node] / 2;
        starts[2 * node] = starts[node];
        starts[2 * node + 1] = starts[node] + spans[node] / 2;
    }
    Polynomial input_poly{};
    for (std::size_t i = 0; i < n; ++i) input_poly[i] = input[2 + i];
    remainder_lengths[1] = remainder(input_poly, n, products[1], product_lengths[1], remainders[1]);
    for (std::size_t node = 1; node < leaf_base; ++node)
        for (std::size_t side = 0; side < 2; ++side) {
            const auto child = 2 * node + side;
            if (starts[child] < m)
                remainder_lengths[child] = remainder(remainders[node], remainder_lengths[node],
                    products[child], product_lengths[child], remainders[child]);
        }
    for (std::size_t i = 0; i < m; ++i) store_le(output, 8 * i, remainders[leaf_base + i][0]);
    return static_cast<std::int64_t>(bytes);
}
