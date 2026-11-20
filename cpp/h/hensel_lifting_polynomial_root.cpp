#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_degree = 4;
constexpr std::int64_t max_prime = 43;
constexpr std::int64_t max_exponent = 6;
constexpr std::int64_t max_modulus = 100000;
constexpr std::size_t max_length = 10;

std::int64_t normalized_mod(std::int64_t value, std::int64_t modulus) {
    const auto result = value % modulus;
    return result < 0 ? result + modulus : result;
}

bool is_prime(std::int64_t value) {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor * divisor <= value; ++divisor)
        if (value % divisor == 0) return false;
    return true;
}

std::int64_t evaluate(const std::int64_t* coefficients, std::int64_t degree,
                      std::int64_t x, std::int64_t modulus) {
    std::int64_t result = 0;
    for (auto index = degree; index >= 0; --index)
        result = normalized_mod(result * x + coefficients[index], modulus);
    return result;
}

std::int64_t derivative(const std::int64_t* coefficients, std::int64_t degree,
                        std::int64_t x, std::int64_t prime) {
    std::int64_t result = 0;
    for (auto index = degree; index >= 1; --index)
        result = normalized_mod(result * x + index * coefficients[index], prime);
    return result;
}
}

extern "C" std::int64_t hensel_lifting_polynomial_root(
    const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 6 || length > max_length) return -1;
    const auto degree = input[0], prime = input[1], exponent = input[2], seed = input[3];
    if (degree < 1 || degree > max_degree || prime < 2 || prime > max_prime ||
        exponent < 1 || exponent > max_exponent || seed < 0 || seed >= prime ||
        length != static_cast<std::size_t>(degree + 5) || !is_prime(prime)) return -1;
    const auto* coefficients = input + 4;
    for (std::int64_t i = 0; i <= degree; ++i)
        if (coefficients[i] < -1000 || coefficients[i] > 1000) return -1;

    std::int64_t modulus = 1;
    for (std::int64_t i = 0; i < exponent; ++i) {
        if (modulus > max_modulus / prime) return -1;
        modulus *= prime;
    }
    if (evaluate(coefficients, degree, seed, prime) != 0) return -1;
    const auto derivative_value = derivative(coefficients, degree, seed, prime);
    if (derivative_value == 0) return -1;
    std::int64_t inverse = 0;
    for (std::int64_t candidate = 1; candidate < prime; ++candidate) {
        if (derivative_value * candidate % prime == 1) {
            inverse = candidate;
            break;
        }
    }
    if (inverse == 0) return -1;

    auto root = seed;
    auto power = prime;
    for (std::int64_t stage = 1; stage < exponent; ++stage) {
        const auto next_power = power * prime;
        const auto residue = evaluate(coefficients, degree, root, next_power);
        const auto quotient_digit = residue / power;
        const auto correction = normalized_mod(-quotient_digit * inverse, prime);
        root += correction * power;
        power = next_power;
    }
    return root;
}
