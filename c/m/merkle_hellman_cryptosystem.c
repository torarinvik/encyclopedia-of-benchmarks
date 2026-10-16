#include <stddef.h>
#include <stdint.h>

static uint64_t gcd_u64(uint64_t a, uint64_t b) {
    while (b != 0) {
        const uint64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static uint64_t add_mod(uint64_t a, uint64_t b, uint64_t modulus) {
    return a >= modulus - b ? a - (modulus - b) : a + b;
}

static uint64_t mul_mod(uint64_t a, uint64_t b, uint64_t modulus) {
    uint64_t result = 0;
    a %= modulus;
    while (b != 0) {
        if ((b & 1) != 0) result = add_mod(result, a, modulus);
        b >>= 1;
        if (b != 0) a = add_mod(a, a, modulus);
    }
    return result;
}

static uint64_t inverse_mod(uint64_t value, uint64_t modulus) {
    uint64_t old_r = modulus, r = value % modulus;
    uint64_t old_t = 0, t = 1;
    while (r != 0) {
        const uint64_t quotient = old_r / r;
        const uint64_t next_r = old_r % r;
        const uint64_t product = mul_mod(quotient % modulus, t, modulus);
        const uint64_t next_t = old_t >= product ? old_t - product : modulus - (product - old_t);
        old_r = r;
        r = next_r;
        old_t = t;
        t = next_t;
    }
    return old_t;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t merkle_hellman_cryptosystem(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 12 || length > 43) return -1;
    if (input[0] < 0 || input[0] > 127) return -1;
    if (input[10] < 1 || input[10] > 32) return -1;
    const size_t draw_count = (size_t)input[10];
    if (length != 11 + draw_count) return -1;

    const uint64_t word_max = UINT64_C(4294967295);
    uint64_t easy[8];
    uint64_t sum = UINT64_C(4294967296);
    for (size_t index = 0; index < 8; ++index) {
        if (input[1 + index] < 0 || (uint64_t)input[1 + index] > word_max) return -1;
        easy[index] = sum + (uint64_t)input[1 + index];
        sum += easy[index];
    }
    if (input[9] < 0 || (uint64_t)input[9] > word_max) return -1;
    const uint64_t modulus = sum + (uint64_t)input[9];
    for (size_t index = 0; index < draw_count; ++index) {
        const int64_t draw_value = input[11 + index];
        if (draw_value < 0 || (uint64_t)draw_value > modulus) return -1;
        const uint64_t divisor = gcd_u64((uint64_t)draw_value, modulus);
        if (index + 1 < draw_count && divisor == 1) return -1;
        if (index + 1 == draw_count && divisor != 1) return -1;
    }
    if (output == NULL || capacity < 17) return -2;

    const uint64_t multiplier = (uint64_t)input[10 + draw_count];
    uint64_t hard[8];
    for (size_t index = 0; index < 8; ++index)
        hard[index] = mul_mod(multiplier, easy[index], modulus);

    uint64_t ciphertext = 0;
    const uint64_t message = (uint64_t)input[0];
    for (int bit_index = 7; bit_index >= 0; --bit_index)
        if (((message >> bit_index) & 1) != 0)
            ciphertext += hard[7 - bit_index];

    const uint64_t inverse = inverse_mod(multiplier, modulus);
    uint64_t residue = mul_mod(inverse, ciphertext % modulus, modulus);
    uint8_t decoded = 0;
    for (size_t index = 0; index < 8; ++index) {
        const uint64_t weight = easy[7 - index];
        if (residue >= weight) {
            residue -= weight;
            decoded = (uint8_t)(decoded | (uint8_t)(1u << index));
        }
    }
    if (residue != 0 || decoded != (uint8_t)message) return -1;

    put_i64_le(output, 0, (int64_t)ciphertext);
    put_i64_le(output, 8, 1);
    output[16] = decoded;
    return 17;
}
