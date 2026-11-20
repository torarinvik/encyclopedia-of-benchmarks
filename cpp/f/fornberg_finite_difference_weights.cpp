#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MODULUS = 998244353;
constexpr std::size_t MAX_NODES = 8;
constexpr std::size_t MAX_INPUT_LENGTH = 12;

std::int64_t mod_norm(std::int64_t value) noexcept {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t fornberg_finite_difference_weights(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const auto n_value = input[0];
    const auto order_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_NODES)
        || order_value < 0 || order_value > 3 || order_value >= n_value
        || length != static_cast<std::size_t>(n_value) + 3) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto target = input[2];
    if (target < 0 || target >= MODULUS) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto node = input[3 + i];
        if (node < 0 || node >= MODULUS) return -1;
        for (std::size_t j = 0; j < i; ++j) if (node == input[3 + j]) return -1;
    }

    std::int64_t table[MAX_NODES][4]{};
    table[0][0] = 1;
    std::int64_t previous_product = 1;
    for (std::size_t new_index = 1; new_index < n; ++new_index) {
        std::int64_t old_last[4];
        for (std::size_t d = 0; d < 4; ++d) old_last[d] = table[new_index - 1][d];
        std::int64_t product = 1;
        const auto node = input[3 + new_index];
        const auto factor = mod_norm(node - target);
        const int max_d = new_index < static_cast<std::size_t>(order_value)
            ? static_cast<int>(new_index) : static_cast<int>(order_value);
        for (std::size_t old_index = 0; old_index < new_index; ++old_index) {
            const auto difference = mod_norm(node - input[3 + old_index]);
            product = product * difference % MODULUS;
            const auto inverse_difference = mod_pow(difference, MODULUS - 2);
            for (int d = max_d; d >= 0; --d) {
                const auto lower = d == 0 ? 0 : table[old_index][d - 1];
                const auto numerator = mod_norm(factor * table[old_index][d] - d * lower);
                table[old_index][d] = numerator * inverse_difference % MODULUS;
            }
        }
        const auto product_inverse = mod_pow(product, MODULUS - 2);
        const auto last_factor = mod_norm(input[2 + new_index] - target);
        for (int d = 0; d <= max_d; ++d) {
            const auto lower = d == 0 ? 0 : old_last[d - 1];
            const auto numerator = mod_norm(d * lower - last_factor * old_last[d]);
            table[new_index][d] = previous_product * product_inverse % MODULUS * numerator % MODULUS;
        }
        previous_product = product;
    }

    const auto required = 8 * (n + 1);
    if (output == nullptr || capacity < required) return -2;
    store_i64_le(output, 0, n_value);
    for (std::size_t i = 0; i < n; ++i)
        store_i64_le(output, 8 * (i + 1), table[i][static_cast<std::size_t>(order_value)]);
    return static_cast<std::int64_t>(required);
}
