module mono_alphabetic;

const usz MAX_TEXT_LENGTH = 256;
const usz MAX_PARSEABLE_INPUT_LENGTH = 285;
const ulong FNV_OFFSET_BASIS = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;
const ulong MASK_63 = 0x7ffffffffffffffful;

fn long mono_alphabetic(long* input, usz length) @export("mono_alphabetic") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long operation = input[0];
    long raw_text_length = input[1];
    if ((operation != 0 && operation != 1) || raw_text_length < 1 || raw_text_length > 256) return -1;
    usz text_length = (usz)raw_text_length;
    if (length != 28 + text_length) return -1;

    bool[26] seen = zeroed;
    int[26] inverse;
    for (usz i = 0; i < 26; i += 1) {
        long value = input[2 + i];
        if (value < 65 || value > 90) return -1;
        usz index = (usz)(value - 65);
        if (seen[index]) return -1;
        seen[index] = true;
        inverse[index] = (int)i;
    }
    for (usz i = 0; i < text_length; i += 1)
        if (input[28 + i] < 65 || input[28 + i] > 90) return -1;

    ulong hash = FNV_OFFSET_BASIS;
    ulong length_word = (ulong)text_length;
    for (usz byte = 0; byte < 8; byte += 1) {
        hash = (hash ^ (length_word & 255ul)) * FNV_PRIME;
        length_word >>= 8;
    }
    for (usz i = 0; i < text_length; i += 1) {
        usz index = (usz)(input[28 + i] - 65);
        long mapped = operation == 0 ? input[2 + index] : 65 + inverse[index];
        hash = (hash ^ (ulong)mapped) * FNV_PRIME;
    }
    return (long)(hash & MASK_63);
}
