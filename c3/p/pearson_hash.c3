module pearson_hash;

const usz TABLE_SIZE = 256;
const usz MAX_TEXT = 64;
const usz MAX_WORDS = 321;

fn long pearson_hash(long* input, usz length) @export("pearson_hash") {
    if (input == null || length < 257 || length > MAX_WORDS + 1) return -1;
    long declared = input[0];
    if (declared < 0 || declared > (long)MAX_TEXT || length != 257 + (usz)declared) return -1;

    u8[256] table;
    bool[256] used = zeroed;
    for (usz slot = 0; slot < TABLE_SIZE; slot++) {
        long value = input[1 + slot];
        if (value < 0 || value > 255) return -1;
        usz byte = (usz)value;
        if (used[byte]) return -1;
        used[byte] = true;
        table[slot] = (u8)byte;
    }

    for (usz offset = 0; offset < (usz)declared; offset++) {
        long value = input[257 + offset];
        if (value < 0 || value > 255) return -1;
    }
    u8 state = 0;
    for (usz offset = 0; offset < (usz)declared; offset++) {
        u8 byte = (u8)input[257 + offset];
        state = table[(usz)(state ^ byte)];
    }
    return (long)state;
}
