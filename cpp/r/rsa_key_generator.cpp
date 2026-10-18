#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t min_key_size = 2;
constexpr std::int64_t max_key_size = 20;
constexpr std::int64_t max_draws = 1024;
constexpr std::size_t max_packed_length = 1027;
constexpr std::uint64_t fnv_offset_basis = 14695981039346656037ULL;
constexpr std::uint64_t fnv_prime = 1099511628211ULL;
constexpr std::uint64_t low_63_mask = 0x7fffffffffffffffULL;

struct DrawState {
    const std::int64_t *values;
    std::size_t length;
    std::size_t cursor;
    std::int64_t key_size;
    bool failed;
};

bool next_draw(DrawState &state, std::int64_t low, std::int64_t high, std::int64_t &result) noexcept
{
    if (state.cursor >= state.length) { state.failed = true; return false; }
    const std::int64_t value = state.values[state.cursor++];
    if (value < low || value >= high) { state.failed = true; return false; }
    result = value;
    return true;
}

std::int64_t gcd_i64(std::int64_t a, std::int64_t b) noexcept
{
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a < 0 ? -a : a;
}

std::int64_t power_mod_i64(std::int64_t base, std::int64_t exponent, std::int64_t modulus) noexcept
{
    std::int64_t result = 1;
    std::int64_t power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}

bool rabin_miller(std::int64_t num, DrawState &state) noexcept
{
    std::int64_t s = num - 1, t = 0;
    while ((s % 2) == 0) { s /= 2; ++t; }
    for (int round = 0; round < 5; ++round) {
        std::int64_t base;
        if (!next_draw(state, 2, num - 1, base)) return false;
        std::int64_t value = power_mod_i64(base, s, num);
        if (value != 1) {
            std::int64_t i = 0;
            while (value != num - 1) {
                if (i == t - 1) return false;
                ++i;
                value = (value * value) % num;
            }
        }
    }
    return true;
}

bool is_prime_low_num(std::int64_t num, DrawState &state) noexcept
{
    if (num < 2) return false;
    if (num <= 997) {
        for (std::int64_t divisor = 2; divisor * divisor <= num; ++divisor)
            if (num % divisor == 0) return false;
        return true;
    }
    for (std::int64_t divisor = 2; divisor <= 997; ++divisor)
        if (num % divisor == 0) return false;
    return rabin_miller(num, state);
}

bool generate_large_prime(DrawState &state, std::int64_t &prime) noexcept
{
    const std::int64_t low = std::int64_t{1} << (state.key_size - 1);
    const std::int64_t high = std::int64_t{1} << state.key_size;
    while (!state.failed) {
        std::int64_t candidate;
        if (!next_draw(state, low, high, candidate)) return false;
        if (is_prime_low_num(candidate, state)) { prime = candidate; return true; }
    }
    return false;
}

std::int64_t find_mod_inverse(std::int64_t a, std::int64_t modulus) noexcept
{
    if (gcd_i64(a, modulus) != 1) return invalid_result;
    std::int64_t u1 = 1, u2 = 0, u3 = a;
    std::int64_t v1 = 0, v2 = 1, v3 = modulus;
    while (v3 != 0) {
        const std::int64_t quotient = u3 / v3;
        const std::int64_t next_v1 = u1 - quotient * v1;
        const std::int64_t next_v2 = u2 - quotient * v2;
        const std::int64_t next_v3 = u3 - quotient * v3;
        u1 = v1; u2 = v2; u3 = v3;
        v1 = next_v1; v2 = next_v2; v3 = next_v3;
    }
    return u1 % modulus;
}

std::uint64_t hash_i64(std::uint64_t hash, std::int64_t value) noexcept
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte)
        hash = (hash ^ ((bits >> (byte * 8)) & 255ULL)) * fnv_prime;
    return hash;
}
} // namespace

extern "C" std::int64_t rsa_key_generator(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2 || length > max_packed_length) return invalid_result;
    const auto key_size = packed[0];
    const auto draw_count = packed[1];
    if (key_size < min_key_size || key_size > max_key_size || draw_count < 0 || draw_count > max_draws ||
        length != static_cast<std::size_t>(2 + draw_count)) return invalid_result;
    const std::int64_t draw_limit = std::int64_t{1} << key_size;
    for (std::size_t i = 0; i < static_cast<std::size_t>(draw_count); ++i)
        if (packed[2 + i] < 2 || packed[2 + i] >= draw_limit) return invalid_result;

    DrawState state{packed, length, 2, key_size, false};
    std::int64_t p, q;
    if (!generate_large_prime(state, p) || !generate_large_prime(state, q)) return invalid_result;
    const std::int64_t n = p * q;
    const std::int64_t phi = (p - 1) * (q - 1);
    const std::int64_t low = std::int64_t{1} << (key_size - 1);
    const std::int64_t high = std::int64_t{1} << key_size;
    std::int64_t e;
    while (true) {
        if (!next_draw(state, low, high, e)) return invalid_result;
        if (gcd_i64(e, phi) == 1) break;
    }
    const std::int64_t d = find_mod_inverse(e, phi);
    std::uint64_t hash = fnv_offset_basis;
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, e);
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, d);
    return static_cast<std::int64_t>(hash & low_63_mask);
}
