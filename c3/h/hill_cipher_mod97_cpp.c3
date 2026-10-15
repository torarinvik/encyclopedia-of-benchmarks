module hill_cipher_mod97_cpp;

const char[97] ALPHABET = {65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32};
fn int alphabet_index(long value) {
    for (int index = 0; index < 97; index += 1) if ((long)(ubyte)ALPHABET[index] == value) return index;
    return -1;
}

fn long hill_cipher_mod97_cpp(long* values, usz length, char* output, usz capacity) @export("hill_cipher_mod97_cpp") {
    if (values == null || length < 3 || length > 258) return -1;
    long operation = values[0], raw_length = values[1];
    if ((operation != 0 && operation != 1) || raw_length < 1 || raw_length > 256 || length != (usz)raw_length + 2) return -1;
    usz text_length = (usz)raw_length;
    char[256] indices;
    for (usz index = 0; index < text_length; index += 1) {
        int mapped = alphabet_index(values[index + 2]);
        if (mapped < 0) return -1;
        indices[index] = (char)mapped;
    }
    usz output_length = text_length + text_length % 2;
    if (output == null || capacity < output_length) return -2;
    long key0 = operation == 0 ? 2 : 84;
    long key1 = operation == 0 ? 5 : 27;
    long key2 = operation == 0 ? 1 : 83;
    long key3 = operation == 0 ? 6 : 28;
    for (usz offset = 0; offset < output_length; offset += 2) {
        long first = (long)(ubyte)indices[offset];
        long second = offset + 1 < text_length ? (long)(ubyte)indices[offset + 1] : 0;
        usz row0 = (usz)((key0 * first + key1 * second) % 97);
        usz row1 = (usz)((key2 * first + key3 * second) % 97);
        output[offset] = ALPHABET[row0];
        output[offset + 1] = ALPHABET[row1];
    }
    return (long)output_length;
}
