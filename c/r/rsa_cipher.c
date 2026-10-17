#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_VALUES 4

int64_t rsa_cipher_encrypt_ascii(const int64_t *input, size_t input_length)
{
    if (input == NULL || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_VALUES ||
        input_length != 3) return -1;

    const int64_t ascii_code = input[0];
    const int64_t exponent = input[1];
    const int64_t modulus = input[2];
    if (ascii_code < 0 || ascii_code > 127 || modulus < 128 || modulus > 65535 ||
        exponent < 1 || exponent >= modulus) return -1;

    int64_t result = 1;
    int64_t base = ascii_code % modulus;
    int64_t power = exponent;
    while (power > 0) {
        if ((power & 1) != 0) result = (result * base) % modulus;
        power >>= 1;
        if (power > 0) base = (base * base) % modulus;
    }
    return result;
}
