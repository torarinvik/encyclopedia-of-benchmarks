#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_nodes = 12;
constexpr std::size_t max_length = 27;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t newton_divided_difference_interpolation(
        const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > max_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_nodes)) return -1;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != 2 + 2 * count) return -1;
    std::int64_t nodes[max_nodes], differences[max_nodes];
    for (std::size_t i = 0; i < count; ++i) {
        nodes[i] = input[1 + i];
        differences[i] = input[1 + count + i];
        if (nodes[i] < 0 || nodes[i] >= modulus || differences[i] < 0 || differences[i] >= modulus) return -1;
        for (std::size_t j = 0; j < i; ++j) if (nodes[i] == nodes[j]) return -1;
    }
    const auto query = input[length - 1];
    if (query < 0 || query >= modulus) return -1;
    for (std::size_t order = 1; order < count; ++order) {
        for (std::size_t i = count; i-- > order;) {
            auto numerator = differences[i] - differences[i - 1];
            if (numerator < 0) numerator += modulus;
            auto denominator = nodes[i] - nodes[i - order];
            if (denominator < 0) denominator += modulus;
            differences[i] = numerator * mod_pow(denominator, modulus - 2) % modulus;
        }
    }
    auto result = differences[count - 1];
    for (std::size_t i = count - 1; i-- > 0;) {
        auto factor = query - nodes[i];
        if (factor < 0) factor += modulus;
        result = (result * factor + differences[i]) % modulus;
    }
    return result;
}
