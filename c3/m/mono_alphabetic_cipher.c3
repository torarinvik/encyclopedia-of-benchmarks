module mono_alphabetic_cipher;

const usz MAX_PARSEABLE_INPUT_LENGTH = 183;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong MASK_63 = 0x7ffffffffffffffful;

fn long mono_alphabetic_cipher(long* input, usz length) @export("mono_alphabetic_cipher") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long operation = input[0], raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 0 || raw_text_length > 128) return -1;
    usz text_length = (usz)raw_text_length;
    if (length != 54 + text_length) return -1;

    bool[26] key_seen = zeroed;
    bool[26] alphabet_seen = zeroed;
    int[26] key_inverse;
    int[26] alphabet_inverse;
    for (usz i = 0; i < 26; i += 1) {
        long key_value = input[2 + i], alphabet_value = input[28 + i];
        if (key_value < 65 || key_value > 90 || alphabet_value < 65 || alphabet_value > 90) return -1;
        usz key_index = (usz)(key_value - 65), alphabet_index = (usz)(alphabet_value - 65);
        if (key_seen[key_index] || alphabet_seen[alphabet_index]) return -1;
        key_seen[key_index] = true; alphabet_seen[alphabet_index] = true;
        key_inverse[key_index] = (int)i; alphabet_inverse[alphabet_index] = (int)i;
    }
    usz output_length = 0;
    for (usz i = 0; i < text_length; i += 1) {
        long value = input[54 + i];
        bool valid = value == 32 || (value >= 48 && value <= 57) ||
            (value >= 65 && value <= 90) || (value >= 97 && value <= 122);
        if (!valid) return -1;
        if (value < 48 || value > 57) output_length += 1;
    }

    ulong hash = FNV_OFFSET_BASIS, length_word = (ulong)output_length;
    for (usz byte = 0; byte < 8; byte += 1) {
        hash = (hash ^ (length_word & 255ul)) * FNV_PRIME;
        length_word >>= 8;
    }
    for (usz i = 0; i < text_length; i += 1) {
        long value = input[54 + i];
        if (value >= 48 && value <= 57) continue;
        long mapped;
        if (value == 32) mapped = value;
        else {
            bool lower = value >= 97 && value <= 122;
            usz letter = (usz)(lower ? value - 97 : value - 65);
            usz index = (usz)(operation == 0 ? alphabet_inverse[letter] : key_inverse[letter]);
            long target = operation == 0 ? input[2 + index] : input[28 + index];
            mapped = lower ? target + 32 : target;
        }
        hash = (hash ^ (ulong)mapped) * FNV_PRIME;
    }
    return (long)(hash & MASK_63);
}
