#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(1))
#define MAX_INPUT_LENGTH ((size_t)69)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW_63_MASK UINT64_C(0x7fffffffffffffff)

static int64_t big_integer_mod_pow(int64_t base, int64_t exponent, int64_t modulus)
{
    int64_t result = 1;
    int64_t power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}

static uint64_t hash_u32(uint64_t hash, uint32_t value)
{
    for (unsigned byte = 0; byte < 4; ++byte)
        hash = (hash ^ ((value >> (byte * 8)) & UINT32_C(255))) * FNV_PRIME;
    return hash;
}

int64_t rsa_java_big_integer(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 5 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t modulus = packed[0];
    const int64_t public_exponent = packed[1];
    const int64_t private_exponent = packed[2];
    const int64_t message_length = packed[3];
    if (modulus < 128 || modulus > 55295 || public_exponent < 1 || public_exponent > 1000000 ||
        private_exponent < 1 || private_exponent > 1000000 || message_length < 1 || message_length > 64 ||
        length != (size_t)(4 + message_length)) return INVALID_RESULT;
    for (size_t i = 0; i < (size_t)message_length; ++i)
        if (packed[4 + i] < 0 || packed[4 + i] > 127 || packed[4 + i] >= modulus) return INVALID_RESULT;

    uint64_t hash = FNV_OFFSET_BASIS;
    for (size_t i = 0; i < (size_t)message_length; ++i)
        hash = hash_u32(hash, (uint32_t)big_integer_mod_pow(packed[4 + i], public_exponent, modulus));
    for (size_t i = 0; i < (size_t)message_length; ++i) {
        const int64_t ciphertext = big_integer_mod_pow(packed[4 + i], public_exponent, modulus);
        const int64_t recovered = big_integer_mod_pow(ciphertext, private_exponent, modulus);
        hash = hash_u32(hash, (uint32_t)recovered);
    }
    return (int64_t)(hash & LOW_63_MASK);
}
