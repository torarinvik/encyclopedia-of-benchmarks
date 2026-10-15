module brute_force_caesar_cipher;

const MAX_MESSAGE_LENGTH = 64;
const KEY_COUNT = 26;

fn long brute_force_caesar_cipher(long* input, usz length, char* output, usz capacity)
    @export("brute_force_caesar_cipher") {
    if (length > MAX_MESSAGE_LENGTH || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 127) return -1;
    usz needed = length * KEY_COUNT + (KEY_COUNT - 1);
    if (output == null || capacity < needed) return -2;
    usz position = 0;
    for (usz key = 0; key < KEY_COUNT; key++) {
        for (usz i = 0; i < length; i++) {
            long value = input[i];
            if (value >= 'A' && value <= 'Z') value = 'A' + (value - 'A' + 26 - (long)key) % 26;
            output[position++] = (char)value;
        }
        if (key + 1 < KEY_COUNT) output[position++] = '\n';
    }
    return KEY_COUNT;
}
