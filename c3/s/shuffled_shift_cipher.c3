module shuffled_shift_cipher;

const char* ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n";
const int ALPHABET_LENGTH = 97;
const int PASSCODE_MAX = 20;
const int PLAINTEXT_MAX = 256;
const usz INPUT_MAX_PARSEABLE = 279;

fn long shuffled_shift_cipher(long* input, usz input_length, char* output, usz output_capacity)
    @export("shuffled_shift_cipher")
{
    if (input == null || input_length < 2 || input_length > INPUT_MAX_PARSEABLE) return -1;

    long passcode_length_value = input[0];
    long plaintext_length_value = input[1];
    if (passcode_length_value < 1 || passcode_length_value > PASSCODE_MAX ||
        plaintext_length_value < 0 || plaintext_length_value > PLAINTEXT_MAX) return -1;

    usz passcode_length = (usz)passcode_length_value;
    usz plaintext_length = (usz)plaintext_length_value;
    if (input_length != 2 + passcode_length + plaintext_length) return -1;

    bool[128] breakpoint;
    for (int i = 0; i < 128; i++) breakpoint[i] = false;
    for (usz i = 0; i < passcode_length; i++) {
        long value = input[2 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
              (value >= '0' && value <= '9'))) return -1;
        breakpoint[(int)value] = true;
    }
    for (usz i = 0; i < plaintext_length; i++) {
        long value = input[2 + passcode_length + i];
        if (value < 0 || value >= 128) return -1;
        bool found = false;
        for (int j = 0; j < ALPHABET_LENGTH; j++) {
            if ((int)ALPHABET[j] == (int)value) {
                found = true;
                break;
            }
        }
        if (!found) return -1;
    }

    int[ALPHABET_LENGTH] key;
    int[128] key_index;
    int[ALPHABET_LENGTH] segment;
    for (int i = 0; i < 128; i++) key_index[i] = -1;
    usz key_length = 0;
    usz segment_length = 0;
    for (int i = 0; i < ALPHABET_LENGTH; i++) {
        int value = (int)ALPHABET[i];
        segment[segment_length++] = value;
        if (breakpoint[value] || i + 1 == ALPHABET_LENGTH) {
            while (segment_length > 0) key[key_length++] = segment[--segment_length];
        }
    }
    for (int i = 0; i < ALPHABET_LENGTH; i++) key_index[key[i]] = i;

    int shift = 0;
    for (usz i = 0; i < passcode_length; i++) {
        int value = (int)input[2 + i];
        shift += (i % 2 == 0) ? value : -value;
    }
    if (shift <= 0) shift = (int)passcode_length;
    shift %= ALPHABET_LENGTH;

    if (output == null || output_capacity < plaintext_length) return -2;
    for (usz i = 0; i < plaintext_length; i++) {
        int value = (int)input[2 + passcode_length + i];
        int index = key_index[value];
        output[i] = (char)key[(index + shift) % ALPHABET_LENGTH];
    }
    return (long)plaintext_length;
}
