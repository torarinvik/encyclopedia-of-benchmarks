#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MODULUS = 998244353;
constexpr std::size_t MAX_INPUT_LENGTH = 19;
constexpr std::size_t MAX_NODES = 8;

std::int64_t mod_pow(std::int64_t base, std::int64_t exponent) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}
}

extern "C" std::int64_t barycentric_lagrange_evaluation(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const auto count_value = input[0];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(MAX_NODES)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 * count + 2) return -1;
    for (std::size_t index = 1; index < length; ++index)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    for (std::size_t left = 0; left < count; ++left)
        for (std::size_t right = 0; right < left; ++right)
            if (input[1 + left] == input[1 + right]) return -1;

    std::int64_t weights[MAX_NODES] = {};
    for (std::size_t index = 0; index < count; ++index) {
        std::int64_t product = 1;
        const auto node = input[1 + index];
        for (std::size_t other = 0; other < count; ++other) {
            if (other == index) continue;
            const auto difference = (node - input[1 + other] + MODULUS) % MODULUS;
            product = product * difference % MODULUS;
        }
        weights[index] = mod_pow(product, MODULUS - 2);
    }

    const auto ordinate_start = 1 + count;
    const auto query = input[2 * count + 1];
    for (std::size_t index = 0; index < count; ++index)
        if (query == input[1 + index]) return input[ordinate_start + index];
    std::int64_t numerator = 0;
    std::int64_t denominator = 0;
    for (std::size_t index = 0; index < count; ++index) {
        const auto difference = (query - input[1 + index] + MODULUS) % MODULUS;
        const auto term = weights[index] * mod_pow(difference, MODULUS - 2) % MODULUS;
        numerator = (numerator + term * input[ordinate_start + index]) % MODULUS;
        denominator = (denominator + term) % MODULUS;
    }
    if (denominator == 0) return -1;
    return numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
}
