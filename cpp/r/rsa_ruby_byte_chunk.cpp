#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::size_t max_input_length = 69;
constexpr std::uint64_t fnv_offset_basis = 14695981039346656037ULL;
constexpr std::uint64_t fnv_prime = 1099511628211ULL;
constexpr std::uint64_t low_63_mask = 0x7fffffffffffffffULL;

std::int64_t bounded_power(std::int64_t base, std::int64_t exponent) noexcept
{
    std::int64_t result = 1;
    for (std::int64_t i = 0; i < exponent; ++i) result *= base;
    return result;
}

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t value) noexcept
{
    return (hash ^ value) * fnv_prime;
}
}

extern "C" std::int64_t rsa_ruby_byte_chunk(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 5 || length > max_input_length) return invalid_result;
    const auto modulus = packed[0];
    const auto public_exponent = packed[1];
    const auto private_exponent = packed[2];
    const auto message_length = packed[3];
    if (modulus != 33 || public_exponent < 1 || public_exponent > 7 || private_exponent < 1 ||
        private_exponent > 7 || message_length < 1 || message_length > 64 ||
        length != static_cast<std::size_t>(4 + message_length)) return invalid_result;
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i)
        if (packed[4 + i] < 0 || packed[4 + i] >= modulus) return invalid_result;
    std::int64_t ciphertexts[64];
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i)
        ciphertexts[i] = bounded_power(packed[4 + i], public_exponent) % modulus;
    auto hash = fnv_offset_basis;
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i) {
        const auto value = ciphertexts[i];
        hash = hash_byte(hash, static_cast<std::uint8_t>('0' + value / 10));
        hash = hash_byte(hash, static_cast<std::uint8_t>('0' + value % 10));
    }
    for (std::size_t i = 0; i < static_cast<std::size_t>(message_length); ++i) {
        const auto recovered = bounded_power(ciphertexts[i], private_exponent) % modulus;
        hash = hash_byte(hash, static_cast<std::uint8_t>(recovered));
    }
    return static_cast<std::int64_t>(hash & low_63_mask);
}
