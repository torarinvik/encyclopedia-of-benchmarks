module rsa_cipher;

const usz MAX_PARSEABLE_INPUT_VALUES = 4;

fn long rsa_cipher_encrypt_ascii(long* input, usz input_length)
    @export("rsa_cipher_encrypt_ascii") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_VALUES ||
        input_length != 3) return -1L;

    long ascii_code = input[0];
    long exponent = input[1];
    long modulus = input[2];
    if (ascii_code < 0 || ascii_code > 127 || modulus < 128 || modulus > 65535 ||
        exponent < 1 || exponent >= modulus) return -1L;

    long result = 1;
    long base = ascii_code % modulus;
    long power = exponent;
    while (power > 0) {
        if ((power & 1) != 0) result = (result * base) % modulus;
        power >>= 1;
        if (power > 0) base = (base * base) % modulus;
    }
    return result;
}
