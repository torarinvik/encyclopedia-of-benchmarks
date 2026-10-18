#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-INT64_C(1))
#define MIN_KEY_SIZE INT64_C(2)
#define MAX_KEY_SIZE INT64_C(20)
#define MAX_DRAWS INT64_C(1024)
#define MAX_PACKED_LENGTH ((size_t)1027)
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW_63_MASK UINT64_C(0x7fffffffffffffff)

typedef struct {
    const int64_t *values;
    size_t length;
    size_t cursor;
    int64_t key_size;
    bool failed;
} DrawState;

static bool next_draw(DrawState *state, int64_t low, int64_t high, int64_t *result)
{
    if (state->cursor >= state->length) {
        state->failed = true;
        return false;
    }
    const int64_t value = state->values[state->cursor++];
    if (value < low || value >= high) {
        state->failed = true;
        return false;
    }
    *result = value;
    return true;
}

static int64_t gcd_i64(int64_t a, int64_t b)
{
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a < 0 ? -a : a;
}

static int64_t power_mod_i64(int64_t base, int64_t exponent, int64_t modulus)
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

static bool rabin_miller(int64_t num, DrawState *state)
{
    int64_t s = num - 1;
    int64_t t = 0;
    while ((s % 2) == 0) {
        s /= 2;
        ++t;
    }
    for (int round = 0; round < 5; ++round) {
        int64_t base;
        if (!next_draw(state, 2, num - 1, &base)) return false;
        int64_t value = power_mod_i64(base, s, num);
        if (value != 1) {
            int64_t i = 0;
            while (value != num - 1) {
                if (i == t - 1) return false;
                ++i;
                value = (value * value) % num;
            }
        }
    }
    return true;
}

static bool is_prime_low_num(int64_t num, DrawState *state)
{
    if (num < 2) return false;
    if (num <= 997) {
        for (int64_t divisor = 2; divisor * divisor <= num; ++divisor) {
            if (num % divisor == 0) return false;
        }
        return true;
    }
    for (int64_t divisor = 2; divisor <= 997; ++divisor) {
        if (num % divisor == 0) return false;
    }
    return rabin_miller(num, state);
}

static bool generate_large_prime(DrawState *state, int64_t *prime)
{
    const int64_t low = INT64_C(1) << (state->key_size - 1);
    const int64_t high = INT64_C(1) << state->key_size;
    while (!state->failed) {
        int64_t candidate;
        if (!next_draw(state, low, high, &candidate)) return false;
        if (is_prime_low_num(candidate, state)) {
            *prime = candidate;
            return true;
        }
    }
    return false;
}

static int64_t find_mod_inverse(int64_t a, int64_t modulus)
{
    if (gcd_i64(a, modulus) != 1) return INVALID_RESULT;
    int64_t u1 = 1, u2 = 0, u3 = a;
    int64_t v1 = 0, v2 = 1, v3 = modulus;
    while (v3 != 0) {
        const int64_t quotient = u3 / v3;
        const int64_t next_v1 = u1 - quotient * v1;
        const int64_t next_v2 = u2 - quotient * v2;
        const int64_t next_v3 = u3 - quotient * v3;
        u1 = v1; u2 = v2; u3 = v3;
        v1 = next_v1; v2 = next_v2; v3 = next_v3;
    }
    return u1 % modulus;
}

static uint64_t hash_i64(uint64_t hash, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash = (hash ^ ((bits >> (byte * 8)) & UINT64_C(255))) * FNV_PRIME;
    }
    return hash;
}

int64_t rsa_key_generator(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    const int64_t key_size = packed[0];
    const int64_t draw_count = packed[1];
    if (key_size < MIN_KEY_SIZE || key_size > MAX_KEY_SIZE || draw_count < 0 || draw_count > MAX_DRAWS ||
        length != (size_t)(2 + draw_count)) return INVALID_RESULT;
    const int64_t draw_limit = INT64_C(1) << key_size;
    for (size_t i = 0; i < (size_t)draw_count; ++i) {
        if (packed[2 + i] < 2 || packed[2 + i] >= draw_limit) return INVALID_RESULT;
    }

    DrawState state = {packed, length, 2, key_size, false};
    int64_t p, q;
    if (!generate_large_prime(&state, &p) || !generate_large_prime(&state, &q)) return INVALID_RESULT;
    const int64_t n = p * q;
    const int64_t phi = (p - 1) * (q - 1);
    const int64_t low = INT64_C(1) << (key_size - 1);
    const int64_t high = INT64_C(1) << key_size;
    int64_t e;
    while (true) {
        if (!next_draw(&state, low, high, &e)) return INVALID_RESULT;
        if (gcd_i64(e, phi) == 1) break;
    }
    const int64_t d = find_mod_inverse(e, phi);
    uint64_t hash = FNV_OFFSET_BASIS;
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, e);
    hash = hash_i64(hash, n);
    hash = hash_i64(hash, d);
    return (int64_t)(hash & LOW_63_MASK);
}
