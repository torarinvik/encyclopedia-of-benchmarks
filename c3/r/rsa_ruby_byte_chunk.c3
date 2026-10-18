module rsa_ruby_byte_chunk;

const long INVALID_RESULT = -1;
const usz MAX_INPUT_LENGTH = 69;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong LOW_63_MASK = 0x7ffffffffffffffful;

fn long bounded_power(long base, long exponent) {
    long result = 1;
    for (long i = 0; i < exponent; i += 1) result *= base;
    return result;
}

fn ulong hash_byte(ulong hash, uint8 value) {
    return (hash ^ (ulong)value) * FNV_PRIME;
}

fn long rsa_ruby_byte_chunk(long* packed, usz length) @export("rsa_ruby_byte_chunk") {
    if (packed == null || length < 5 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long modulus = packed[0], public_exponent = packed[1], private_exponent = packed[2], message_length = packed[3];
    if (modulus != 33 || public_exponent < 1 || public_exponent > 7 || private_exponent < 1 || private_exponent > 7 ||
        message_length < 1 || message_length > 64 || length != (usz)(4 + message_length)) return INVALID_RESULT;
    for (usz i = 0; i < (usz)message_length; i += 1)
        if (packed[4 + i] < 0 || packed[4 + i] >= modulus) return INVALID_RESULT;
    long ciphertexts[64];
    for (usz i = 0; i < (usz)message_length; i += 1)
        ciphertexts[i] = bounded_power(packed[4 + i], public_exponent) % modulus;
    ulong hash = FNV_OFFSET_BASIS;
    for (usz i = 0; i < (usz)message_length; i += 1) {
        long value = ciphertexts[i];
        hash = hash_byte(hash, (uint8)('0' + value / 10));
        hash = hash_byte(hash, (uint8)('0' + value % 10));
    }
    for (usz i = 0; i < (usz)message_length; i += 1)
        hash = hash_byte(hash, (uint8)(bounded_power(ciphertexts[i], private_exponent) % modulus));
    return (long)(hash & LOW_63_MASK);
}
