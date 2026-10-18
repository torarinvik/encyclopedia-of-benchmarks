#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::size_t max_input_length = 69;
constexpr std::uint64_t fnv_offset_basis = 14695981039346656037ULL;
constexpr std::uint64_t fnv_prime = 1099511628211ULL;
constexpr std::uint64_t low_63_mask = 0x7fffffffffffffffULL;

std::int64_t big_integer_mod_pow(std::int64_t base, std::int64_t exponent, std::int64_t modulus) noexcept
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

std::uint64_t hash_u32(std::uint64_t hash, std::uint32_t value) noexcept
{
    for (unsigned byte = 0; byte < 4; ++byte)
        hash = (hash ^ ((value >> (byte * 8)) & 255U)) * fnv_prime;
    return hash;
}
}

extern "C" std::int64_t rsa_java_big_integer(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 5 || length > max_input_length) return invalid_result;
    const auto modulus = packed[0];
    const auto public_exponent = packed[1];
    const auto private_exponent = packed[2];
    const auto message_length = packed[3];
    if (modulus < 128 || modulus > 55295 || public_exponent < 1 || public_exponent > 1000000 ||
        private_exponent < 1 || private_exponent > 1000000 || message_length < 1 || message_length > 64 ||
        length != static_cast<std::size_t>(4 + message_length)) return invalid_result;
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i)
        if (packed[4 + i] < 0 || packed[4 + i] > 127 || packed[4 + i] >= modulus) return invalid_result;
    auto hash = fnv_offset_basis;
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i)
        hash = hash_u32(hash, static_cast<std::uint32_t>(big_integer_mod_pow(packed[4 + i], public_exponent, modulus)));
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i) {
        const auto ciphertext = big_integer_mod_pow(packed[4 + i], public_exponent, modulus);
        const auto recovered = big_integer_mod_pow(ciphertext, private_exponent, modulus);
        hash = hash_u32(hash, static_cast<std::uint32_t>(recovered));
    }
    return static_cast<std::int64_t>(hash & low_63_mask);
}
