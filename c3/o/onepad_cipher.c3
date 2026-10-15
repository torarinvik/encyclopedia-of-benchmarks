module onepad_cipher;

const usz MAX_TEXT_LENGTH = 1024;

fn void store_i64_le(long value, char* output) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long onepad_cipher(long* input, usz length, char* output, usz output_capacity) @export("onepad_cipher") {
    if (input == null || length < 2 || length > 2 + 2 * MAX_TEXT_LENGTH) return -1;
    long mode = input[0], count_value = input[1];
    if ((mode != 0 && mode != 1) || count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 2 * count) return -1;
    usz needed = mode == 0 ? 8 * count : count;
    if (output_capacity < needed || (needed > 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) {
        long data = input[2 + index], key = input[2 + count + index];
        if (key < 1 || key > 300) return -1;
        if (mode == 0) {
            if (data < 32 || data > 126) return -1;
            store_i64_le((data + key) * key, output + 8 * index);
        } else {
            long key_square = key * key;
            if (data < key_square || (data - key_square) % key != 0) return -1;
            long plain = (data - key_square) / key;
            if (plain < 32 || plain > 126) return -1;
            output[index] = (char)plain;
        }
    }
    return (long)needed;
}
