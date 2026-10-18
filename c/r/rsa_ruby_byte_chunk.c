#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(1))
#define MAX_INPUT_LENGTH ((size_t)69)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW_63_MASK UINT64_C(0x7fffffffffffffff)

static int64_t bounded_power(int64_t base, int64_t exponent)
{
    int64_t result = 1;
    for (int64_t i = 0; i < exponent; ++i) result *= base;
    return result;
}

static uint64_t hash_byte(uint64_t hash, uint8_t value)
{
    return (hash ^ value) * FNV_PRIME;
}

int64_t rsa_ruby_byte_chunk(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 5 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t modulus = packed[0];
    const int64_t public_exponent = packed[1];
    const int64_t private_exponent = packed[2];
    const int64_t message_length = packed[3];
    if (modulus != 33 || public_exponent < 1 || public_exponent > 7 || private_exponent < 1 ||
        private_exponent > 7 || message_length < 1 || message_length > 64 ||
        length != (size_t)(4 + message_length)) return INVALID_RESULT;
    for (size_t i = 0; i < (size_t)message_length; ++i)
        if (packed[4 + i] < 0 || packed[4 + i] >= modulus) return INVALID_RESULT;

    int64_t ciphertexts[64];
    for (size_t i = 0; i < (size_t)message_length; ++i)
        ciphertexts[i] = bounded_power(packed[4 + i], public_exponent) % modulus;

    uint64_t hash = FNV_OFFSET_BASIS;
    for (size_t i = 0; i < (size_t)message_length; ++i) {
        const int64_t value = ciphertexts[i];
        hash = hash_byte(hash, (uint8_t)('0' + value / 10));
        hash = hash_byte(hash, (uint8_t)('0' + value % 10));
    }
    for (size_t i = 0; i < (size_t)message_length; ++i) {
        const int64_t recovered = bounded_power(ciphertexts[i], private_exponent) % modulus;
        hash = hash_byte(hash, (uint8_t)recovered);
    }
    return (int64_t)(hash & LOW_63_MASK);
}
