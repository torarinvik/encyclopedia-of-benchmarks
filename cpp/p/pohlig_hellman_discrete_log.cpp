#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_p = 3;
constexpr std::int64_t max_p = 1009;
constexpr std::size_t max_factors = 16;
constexpr std::size_t max_parseable_length = 4;

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    for (std::int64_t divisor = 2; divisor * divisor <= value;
         divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t pow_mod(std::int64_t base, std::int64_t exponent,
                     std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    auto factor = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * factor % modulus;
        factor = factor * factor % modulus;
        exponent >>= 1;
    }
    return result;
}

std::size_t factorize(std::int64_t value, std::int64_t* primes,
                      std::int64_t* exponents) noexcept {
    std::size_t count = 0;
    for (std::int64_t divisor = 2; divisor * divisor <= value;
         divisor = divisor == 2 ? 3 : divisor + 2) {
        if (value % divisor != 0) continue;
        std::int64_t exponent = 0;
        do {
            value /= divisor;
            ++exponent;
        } while (value % divisor == 0);
        primes[count] = divisor;
        exponents[count] = exponent;
        ++count;
    }
    if (value > 1) {
        primes[count] = value;
        exponents[count] = 1;
        ++count;
    }
    return count;
}

std::int64_t prime_order_log(std::int64_t generator, std::int64_t target,
                             std::int64_t order, std::int64_t modulus) noexcept {
    std::int64_t step = 1;
    while (step * step < order) ++step;
    std::int64_t baby[64]{};
    std::int64_t value = 1;
    for (std::int64_t j = 0; j < step; ++j) {
        baby[j] = value;
        value = value * generator % modulus;
    }
    const auto giant_factor = pow_mod(pow_mod(generator, step, modulus), modulus - 2, modulus);
    auto probe = target;
    for (std::int64_t i = 0; i <= step; ++i) {
        for (std::int64_t j = 0; j < step; ++j) {
            if (baby[j] == probe) {
                const auto candidate = i * step + j;
                if (candidate < order) return candidate;
            }
        }
        probe = probe * giant_factor % modulus;
    }
    return -1;
}

std::int64_t inverse_mod(std::int64_t value, std::int64_t modulus) noexcept {
    auto old_r = value;
    auto r = modulus;
    std::int64_t old_s = 1;
    std::int64_t s = 0;
    while (r != 0) {
        const auto quotient = old_r / r;
        const auto next_r = old_r - quotient * r;
        const auto next_s = old_s - quotient * s;
        old_r = r; r = next_r;
        old_s = s; s = next_s;
    }
    if (old_r != 1) return -1;
    return (old_s % modulus + modulus) % modulus;
}

std::int64_t pohlig_hellman(std::int64_t p, std::int64_t base,
                            std::int64_t target) noexcept {
    if (target == 0) return -2;
    std::int64_t primes[max_factors]{};
    std::int64_t exponents[max_factors]{};
    const auto factor_count = factorize(p - 1, primes, exponents);
    auto order = p - 1;
    for (std::size_t i = 0; i < factor_count; ++i) {
        while (order % primes[i] == 0 && pow_mod(base, order / primes[i], p) == 1) {
            order /= primes[i];
        }
    }
    if (order == 1) return target == 1 ? 0 : -2;

    std::int64_t order_primes[max_factors]{};
    std::int64_t order_exponents[max_factors]{};
    const auto order_factor_count = factorize(order, order_primes, order_exponents);
    std::int64_t solution = 0;
    std::int64_t combined_modulus = 1;
    for (std::size_t i = 0; i < order_factor_count; ++i) {
        const auto prime = order_primes[i];
        const auto exponent = order_exponents[i];
        std::int64_t component_modulus = 1;
        for (std::int64_t j = 0; j < exponent; ++j) component_modulus *= prime;
        std::int64_t partial_log = 0;
        std::int64_t place = 1;
        const auto prime_generator = pow_mod(base, order / prime, p);
        for (std::int64_t digit_index = 0; digit_index < exponent; ++digit_index) {
            const auto current_power = pow_mod(base, partial_log, p);
            const auto inverse_current = pow_mod(current_power, p - 2, p);
            const auto residual = target * inverse_current % p;
            const auto digit_target = pow_mod(residual, order / (place * prime), p);
            const auto digit = prime_order_log(prime_generator, digit_target, prime, p);
            if (digit < 0) return -2;
            partial_log += digit * place;
            place *= prime;
        }
        if (combined_modulus == 1) {
            solution = partial_log;
            combined_modulus = component_modulus;
        } else {
            const auto inverse = inverse_mod(combined_modulus % component_modulus,
                                             component_modulus);
            if (inverse < 0) return -2;
            const auto difference = (partial_log - solution) % component_modulus;
            const auto adjustment = ((difference + component_modulus) % component_modulus)
                                  * inverse % component_modulus;
            solution += combined_modulus * adjustment;
            combined_modulus *= component_modulus;
        }
    }
    solution %= order;
    return pow_mod(base, solution, p) == target ? solution : -2;
}
}

extern "C" std::int64_t pohlig_hellman_discrete_log(const std::int64_t* input,
                                                     std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length || length != 3) return -1;
    const auto p = input[0];
    const auto base = input[1];
    const auto target = input[2];
    if (p < min_p || p > max_p || !is_prime(p) || base < 1 || base >= p
        || target < 0 || target >= p) return -1;
    return pohlig_hellman(p, base, target);
}
