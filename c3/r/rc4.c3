module rc4;

const usz MAX_KEY_LENGTH = 256;
const usz MAX_PLAINTEXT_LENGTH = 256;
const usz MAX_INPUT_VALUES = 515;

fn long rc4(long* input, usz length, char* output, usz capacity) @export("rc4") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1L;
    long key_length_value = input[0];
    long plaintext_length_value = input[1];
    if (key_length_value < 1L || key_length_value > 256L ||
        plaintext_length_value < 0L || plaintext_length_value > 256L) return -1L;
    usz key_length = (usz)key_length_value;
    usz plaintext_length = (usz)plaintext_length_value;
    if (length != 2 + key_length + plaintext_length) return -1L;
    for (usz index = 0; index < key_length + plaintext_length; index++) {
        long byte = input[2 + index];
        if (byte < 0L || byte > 255L) return -1L;
    }
    if (plaintext_length == 0) return 0L;
    if (output == null || capacity < plaintext_length) return -2L;

    u8[256] state;
    for (usz index = 0; index < 256; index++) state[index] = (u8)index;
    usz j = 0;
    for (usz index = 0; index < 256; index++) {
        j = (j + (usz)state[index] + (usz)input[2 + index % key_length]) & 255;
        u8 temporary = state[index];
        state[index] = state[j];
        state[j] = temporary;
    }

    usz i = 0;
    j = 0;
    for (usz offset = 0; offset < plaintext_length; offset++) {
        i = (i + 1) & 255;
        j = (j + (usz)state[i]) & 255;
        u8 temporary = state[i];
        state[i] = state[j];
        state[j] = temporary;
        usz stream_index = ((usz)state[i] + (usz)state[j]) & 255;
        output[offset] = (char)((u8)input[2 + key_length + offset] ^ state[stream_index]);
    }
    return (long)plaintext_length;
}
