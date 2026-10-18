module rsa_java_big_integer;

const long INVALID_RESULT = -1;
const usz MAX_INPUT_LENGTH = 69;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong LOW_63_MASK = 0x7ffffffffffffffful;

fn long big_integer_mod_pow(long base, long exponent_input, long modulus) {
    long exponent = exponent_input;
    long result = 1, power = base % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * power) % modulus;
        power = (power * power) % modulus;
        exponent /= 2;
    }
    return result;
}

fn ulong hash_u32(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint byte = 0; byte < 4; byte += 1)
        hash = (hash ^ ((bits >> (byte * 8)) & 255ul)) * FNV_PRIME;
    return hash;
}

fn long rsa_java_big_integer(long* packed, usz length) @export("rsa_java_big_integer") {
    if (packed == null || length < 5 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long modulus = packed[0], public_exponent = packed[1], private_exponent = packed[2], message_length = packed[3];
    if (modulus < 128 || modulus > 55295 || public_exponent < 1 || public_exponent > 1000000 ||
        private_exponent < 1 || private_exponent > 1000000 || message_length < 1 || message_length > 64 ||
        length != (usz)(4 + message_length)) return INVALID_RESULT;
    for (usz i = 0; i < (usz)message_length; i += 1)
        if (packed[4 + i] < 0 || packed[4 + i] > 127 || packed[4 + i] >= modulus) return INVALID_RESULT;
    ulong hash = FNV_OFFSET_BASIS;
    for (usz i = 0; i < (usz)message_length; i += 1)
        hash = hash_u32(hash, big_integer_mod_pow(packed[4 + i], public_exponent, modulus));
    for (usz i = 0; i < (usz)message_length; i += 1) {
        long ciphertext = big_integer_mod_pow(packed[4 + i], public_exponent, modulus);
        hash = hash_u32(hash, big_integer_mod_pow(ciphertext, private_exponent, modulus));
    }
    return (long)(hash & LOW_63_MASK);
}
