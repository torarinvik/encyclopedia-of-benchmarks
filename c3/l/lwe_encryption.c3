module lwe_encryption;

const long INVALID_RESULT = -1;
const usz DIMENSION = 32;
const long MODULUS = 3329;
const usz SAMPLES = 128;
const usz MAX_MESSAGE_BYTES = 4;
const usz MAX_PARSEABLE_LENGTH = 8358;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong LOW_63_MASK = 0x7ffffffffffffffful;

fn ulong hash_byte(ulong hash, uint byte) {
    return (hash ^ (ulong)byte) * FNV_PRIME;
}

fn ulong hash_word(ulong hash, long value) {
    ulong word = (ulong)value;
    hash = hash_byte(hash, (uint)(word & 255ul));
    return hash_byte(hash, (uint)((word >> 8) & 255ul));
}

fn long lwe_encryption(long* values, usz length) @export("lwe_encryption") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    long message_length_value = values[0];
    if (message_length_value < 1 || message_length_value > (long)MAX_MESSAGE_BYTES) return INVALID_RESULT;
    usz message_length = (usz)message_length_value;
    usz message_start = 1;
    usz message_end = message_start + message_length;
    usz secret_start = message_end;
    usz matrix_start = secret_start + DIMENSION;
    usz error_start = matrix_start + SAMPLES * DIMENSION;
    usz subset_start = error_start + SAMPLES;
    usz subset_count = message_length * 8 * SAMPLES;
    if (length != subset_start + subset_count) return INVALID_RESULT;

    for (usz i = 0; i < message_length; i += 1)
        if (values[message_start + i] < 0 || values[message_start + i] > 255) return INVALID_RESULT;
    for (usz j = 0; j < DIMENSION; j += 1)
        if (values[secret_start + j] < 0 || values[secret_start + j] >= MODULUS) return INVALID_RESULT;
    for (usz i = 0; i < SAMPLES * DIMENSION; i += 1)
        if (values[matrix_start + i] < 0 || values[matrix_start + i] >= MODULUS) return INVALID_RESULT;
    for (usz i = 0; i < SAMPLES; i += 1)
        if (values[error_start + i] < 0 || values[error_start + i] > 6) return INVALID_RESULT;
    for (usz i = 0; i < subset_count; i += 1)
        if (values[subset_start + i] != 0 && values[subset_start + i] != 1) return INVALID_RESULT;

    long[128] public_b;
    for (usz row = 0; row < SAMPLES; row += 1) {
        long sum = 0;
        for (usz column = 0; column < DIMENSION; column += 1)
            sum += values[matrix_start + row * DIMENSION + column] * values[secret_start + column];
        long error = values[error_start + row] - 3;
        long reduced = (sum + error) % MODULUS;
        if (reduced < 0) reduced += MODULUS;
        public_b[row] = reduced;
    }

    ulong hash = FNV_OFFSET_BASIS;
    uint[4] decoded_message;
    usz subset_cursor = 0;
    for (usz byte_index = 0; byte_index < message_length; byte_index += 1) {
        uint message_byte = (uint)values[message_start + byte_index];
        uint decoded_byte = 0;
        for (usz bit_index = 0; bit_index < 8; bit_index += 1) {
            long message_bit = (long)((message_byte >> (7 - bit_index)) & 1);
            long[32] u_accumulator;
            for (usz column = 0; column < DIMENSION; column += 1) u_accumulator[column] = 0;
            long v_accumulator = message_bit * (MODULUS / 2);
            for (usz row = 0; row < SAMPLES; row += 1) {
                long selected = values[subset_start + subset_cursor];
                subset_cursor += 1;
                if (selected != 0) {
                    for (usz column = 0; column < DIMENSION; column += 1)
                        u_accumulator[column] += values[matrix_start + row * DIMENSION + column];
                    v_accumulator += public_b[row];
                }
            }
            long[32] u;
            for (usz column = 0; column < DIMENSION; column += 1) {
                u[column] = u_accumulator[column] % MODULUS;
                hash = hash_word(hash, u[column]);
            }
            long v = v_accumulator % MODULUS;
            hash = hash_word(hash, v);

            long dot = 0;
            for (usz column = 0; column < DIMENSION; column += 1)
                dot += u[column] * values[secret_start + column];
            long difference = (v - dot) % MODULUS;
            if (difference < 0) difference += MODULUS;
            uint decrypted_bit = difference >= 832 && difference < 2496 ? 1 : 0;
            decoded_byte = (decoded_byte << 1) | decrypted_bit;
        }
        decoded_message[byte_index] = decoded_byte;
    }
    for (usz i = 0; i < message_length; i += 1) hash = hash_byte(hash, decoded_message[i]);
    return (long)(hash & LOW_63_MASK);
}
