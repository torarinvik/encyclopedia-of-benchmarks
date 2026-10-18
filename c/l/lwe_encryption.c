#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(1))
#define DIMENSION 32u
#define MODULUS 3329
#define SAMPLES 128u
#define MAX_MESSAGE_BYTES 4u
#define MAX_PARSEABLE_LENGTH 8358u
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW_63_MASK UINT64_C(0x7fffffffffffffff)

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ (uint64_t)byte) * FNV_PRIME;
}

static uint64_t hash_word(uint64_t hash, int64_t value)
{
    const uint64_t word = (uint64_t)value;
    hash = hash_byte(hash, (uint8_t)(word & UINT64_C(255)));
    return hash_byte(hash, (uint8_t)((word >> 8) & UINT64_C(255)));
}

int64_t lwe_encryption(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    const int64_t message_length_value = values[0];
    if (message_length_value < 1 || message_length_value > (int64_t)MAX_MESSAGE_BYTES) return INVALID_RESULT;
    const size_t message_length = (size_t)message_length_value;
    const size_t message_start = 1;
    const size_t message_end = message_start + message_length;
    const size_t secret_start = message_end;
    const size_t matrix_start = secret_start + DIMENSION;
    const size_t error_start = matrix_start + SAMPLES * DIMENSION;
    const size_t subset_start = error_start + SAMPLES;
    const size_t subset_count = message_length * 8u * SAMPLES;
    if (length != subset_start + subset_count) return INVALID_RESULT;

    for (size_t i = 0; i < message_length; ++i)
        if (values[message_start + i] < 0 || values[message_start + i] > 255) return INVALID_RESULT;
    for (size_t j = 0; j < DIMENSION; ++j)
        if (values[secret_start + j] < 0 || values[secret_start + j] >= MODULUS) return INVALID_RESULT;
    for (size_t index = 0; index < SAMPLES * DIMENSION; ++index)
        if (values[matrix_start + index] < 0 || values[matrix_start + index] >= MODULUS) return INVALID_RESULT;
    for (size_t i = 0; i < SAMPLES; ++i)
        if (values[error_start + i] < 0 || values[error_start + i] > 6) return INVALID_RESULT;
    for (size_t i = 0; i < subset_count; ++i)
        if (values[subset_start + i] != 0 && values[subset_start + i] != 1) return INVALID_RESULT;

    int64_t public_b[SAMPLES];
    for (size_t row = 0; row < SAMPLES; ++row) {
        int64_t sum = 0;
        for (size_t column = 0; column < DIMENSION; ++column)
            sum += values[matrix_start + row * DIMENSION + column] * values[secret_start + column];
        const int64_t error = values[error_start + row] - 3;
        int64_t reduced = (sum + error) % MODULUS;
        if (reduced < 0) reduced += MODULUS;
        public_b[row] = reduced;
    }

    uint64_t hash = FNV_OFFSET_BASIS;
    uint8_t decoded_message[MAX_MESSAGE_BYTES] = {0};
    size_t subset_cursor = 0;
    for (size_t byte_index = 0; byte_index < message_length; ++byte_index) {
        const uint8_t message_byte = (uint8_t)values[message_start + byte_index];
        uint8_t decoded_byte = 0;
        for (size_t bit_index = 0; bit_index < 8; ++bit_index) {
            const int64_t message_bit = (message_byte >> (7u - bit_index)) & 1u;
            int64_t u_accumulator[DIMENSION] = {0};
            int64_t v_accumulator = message_bit * (MODULUS / 2);
            for (size_t row = 0; row < SAMPLES; ++row) {
                const int64_t selected = values[subset_start + subset_cursor++];
                if (selected != 0) {
                    for (size_t column = 0; column < DIMENSION; ++column)
                        u_accumulator[column] += values[matrix_start + row * DIMENSION + column];
                    v_accumulator += public_b[row];
                }
            }
            int64_t u[DIMENSION];
            for (size_t column = 0; column < DIMENSION; ++column) {
                u[column] = u_accumulator[column] % MODULUS;
                hash = hash_word(hash, u[column]);
            }
            const int64_t v = v_accumulator % MODULUS;
            hash = hash_word(hash, v);

            int64_t dot = 0;
            for (size_t column = 0; column < DIMENSION; ++column)
                dot += u[column] * values[secret_start + column];
            int64_t difference = (v - dot) % MODULUS;
            if (difference < 0) difference += MODULUS;
            const int64_t decrypted_bit = (difference >= 832 && difference < 2496) ? 1 : 0;
            decoded_byte = (uint8_t)((decoded_byte << 1) | (uint8_t)decrypted_bit);
        }
        decoded_message[byte_index] = decoded_byte;
    }
    for (size_t i = 0; i < message_length; ++i) hash = hash_byte(hash, decoded_message[i]);
    return (int64_t)(hash & LOW_63_MASK);
}
