#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = -1;
constexpr std::size_t dimension = 32;
constexpr std::size_t samples = 128;
constexpr std::size_t max_message_bytes = 4;
constexpr std::size_t max_parseable_length = 8358;
constexpr std::int64_t modulus = 3329;
constexpr std::uint64_t fnv_offset_basis = 14695981039346656037ULL;
constexpr std::uint64_t fnv_prime = 1099511628211ULL;
constexpr std::uint64_t low_63_mask = 0x7fffffffffffffffULL;

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) noexcept
{
    return (hash ^ static_cast<std::uint64_t>(byte)) * fnv_prime;
}

std::uint64_t hash_word(std::uint64_t hash, std::int64_t value) noexcept
{
    const auto word = static_cast<std::uint64_t>(value);
    hash = hash_byte(hash, static_cast<std::uint8_t>(word & 255ULL));
    return hash_byte(hash, static_cast<std::uint8_t>((word >> 8) & 255ULL));
}
} // namespace

extern "C" std::int64_t lwe_encryption(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 1 || length > max_parseable_length) return invalid_result;
    const auto message_length_value = values[0];
    if (message_length_value < 1 || message_length_value > static_cast<std::int64_t>(max_message_bytes)) return invalid_result;
    const auto message_length = static_cast<std::size_t>(message_length_value);
    const std::size_t message_start = 1;
    const std::size_t message_end = message_start + message_length;
    const std::size_t secret_start = message_end;
    const std::size_t matrix_start = secret_start + dimension;
    const std::size_t error_start = matrix_start + samples * dimension;
    const std::size_t subset_start = error_start + samples;
    const std::size_t subset_count = message_length * 8 * samples;
    if (length != subset_start + subset_count) return invalid_result;

    for (std::size_t i = 0; i < message_length; ++i)
        if (values[message_start + i] < 0 || values[message_start + i] > 255) return invalid_result;
    for (std::size_t j = 0; j < dimension; ++j)
        if (values[secret_start + j] < 0 || values[secret_start + j] >= modulus) return invalid_result;
    for (std::size_t i = 0; i < samples * dimension; ++i)
        if (values[matrix_start + i] < 0 || values[matrix_start + i] >= modulus) return invalid_result;
    for (std::size_t i = 0; i < samples; ++i)
        if (values[error_start + i] < 0 || values[error_start + i] > 6) return invalid_result;
    for (std::size_t i = 0; i < subset_count; ++i)
        if (values[subset_start + i] != 0 && values[subset_start + i] != 1) return invalid_result;

    std::int64_t public_b[samples]{};
    for (std::size_t row = 0; row < samples; ++row) {
        std::int64_t sum = 0;
        for (std::size_t column = 0; column < dimension; ++column)
            sum += values[matrix_start + row * dimension + column] * values[secret_start + column];
        const std::int64_t error = values[error_start + row] - 3;
        std::int64_t reduced = (sum + error) % modulus;
        if (reduced < 0) reduced += modulus;
        public_b[row] = reduced;
    }

    std::uint64_t hash = fnv_offset_basis;
    std::uint8_t decoded_message[max_message_bytes]{};
    std::size_t subset_cursor = 0;
    for (std::size_t byte_index = 0; byte_index < message_length; ++byte_index) {
        const auto message_byte = static_cast<std::uint8_t>(values[message_start + byte_index]);
        std::uint8_t decoded_byte = 0;
        for (std::size_t bit_index = 0; bit_index < 8; ++bit_index) {
            const std::int64_t message_bit = (message_byte >> (7 - bit_index)) & 1U;
            std::int64_t u_accumulator[dimension]{};
            std::int64_t v_accumulator = message_bit * (modulus / 2);
            for (std::size_t row = 0; row < samples; ++row) {
                const auto selected = values[subset_start + subset_cursor++];
                if (selected != 0) {
                    for (std::size_t column = 0; column < dimension; ++column)
                        u_accumulator[column] += values[matrix_start + row * dimension + column];
                    v_accumulator += public_b[row];
                }
            }
            std::int64_t u[dimension];
            for (std::size_t column = 0; column < dimension; ++column) {
                u[column] = u_accumulator[column] % modulus;
                hash = hash_word(hash, u[column]);
            }
            const std::int64_t v = v_accumulator % modulus;
            hash = hash_word(hash, v);

            std::int64_t dot = 0;
            for (std::size_t column = 0; column < dimension; ++column)
                dot += u[column] * values[secret_start + column];
            std::int64_t difference = (v - dot) % modulus;
            if (difference < 0) difference += modulus;
            const std::int64_t decrypted_bit = difference >= 832 && difference < 2496 ? 1 : 0;
            decoded_byte = static_cast<std::uint8_t>((decoded_byte << 1) | static_cast<std::uint8_t>(decrypted_bit));
        }
        decoded_message[byte_index] = decoded_byte;
    }
    for (std::size_t i = 0; i < message_length; ++i) hash = hash_byte(hash, decoded_message[i]);
    return static_cast<std::int64_t>(hash & low_63_mask);
}
