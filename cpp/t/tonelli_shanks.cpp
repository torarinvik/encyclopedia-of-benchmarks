/* Least modular square root using the pinned Tonelli-Shanks flow. */
#include <cstddef>
#include <cstdint>

static std::int64_t mod_pow(std::int64_t base, std::int64_t exponent, std::int64_t modulus)
{
    std::int64_t result = 1;
    base %= modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

static int legendre_symbol(std::int64_t residue, std::int64_t prime)
{
    const auto symbol = mod_pow(residue % prime, (prime - 1) / 2, prime);
    return symbol == prime - 1 ? -1 : static_cast<int>(symbol);
}

extern "C" std::int64_t tonelli_shanks(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length != 2) return -1;
    std::int64_t residue = packed[0];
    const std::int64_t prime = packed[1];
    if (prime <= 2 || (prime & 1) == 0 || prime > 1000003 || residue < 0 || residue >= prime) return -1;
    if (residue == 0) return 0;
    if (legendre_symbol(residue, prime) != 1) return -1;
    if (prime % 4 == 3) {
        const auto root = mod_pow(residue, (prime + 1) / 4, prime);
        return root < prime - root ? root : prime - root;
    }
    std::int64_t q = prime - 1;
    std::int64_t s = 0;
    while ((q & 1) == 0) { q /= 2; ++s; }
    std::int64_t non_residue = 2;
    while (legendre_symbol(non_residue, prime) != -1) ++non_residue;
    std::int64_t c = mod_pow(non_residue, q, prime);
    std::int64_t r = mod_pow(residue, (q + 1) / 2, prime);
    std::int64_t t = mod_pow(residue, q, prime);
    std::int64_t remaining_s = s;
    while (t != 1) {
        std::int64_t test_power = t;
        std::int64_t least_i = 0;
        for (std::int64_t candidate_i = 1; candidate_i < remaining_s; ++candidate_i) {
            test_power = mod_pow(test_power, 2, prime);
            if (test_power == 1) { least_i = candidate_i; break; }
        }
        if (least_i == 0) return -1;
        const auto b = mod_pow(c, INT64_C(1) << (remaining_s - least_i - 1), prime);
        r = (r * b) % prime;
        c = (b * b) % prime;
        t = (t * c) % prime;
        remaining_s = least_i;
    }
    return r < prime - r ? r : prime - r;
}
