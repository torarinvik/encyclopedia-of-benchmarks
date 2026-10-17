module skytale_cipher;

const usz MAX_INPUT_LENGTH = 260;
const usz MAX_TEXT_LENGTH = 256;
const usz MAX_KEY = 256;

fn long skytale_cipher(long* input, usz length, char* output, usz capacity) @export("skytale_cipher") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 1 || input[1] < 1 || input[1] > MAX_KEY ||
        input[2] < 0 || input[2] > MAX_TEXT_LENGTH) return -1;
    usz mode = (usz)input[0], key = (usz)input[1], n = (usz)input[2];
    if (length != 3 + n) return -1;
    for (usz i = 0; i < n; i++) if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    if (output == null || capacity < n) return -2;

    if (mode == 0) {
        usz out = 0;
        for (usz row = 0; row < key; row++)
            for (usz position = row; position < n; position += key) output[out++] = (char)input[3 + position];
    } else {
        usz[MAX_KEY] starts = {0};
        usz[MAX_KEY] used = {0};
        usz base = n / key, extra = n % key;
        for (usz row = 1; row < key; row++) starts[row] = starts[row - 1] + base + (row - 1 < extra ? 1 : 0);
        for (usz position = 0; position < n; position++) {
            usz row = position % key;
            output[position] = (char)input[3 + starts[row] + used[row]];
            used[row]++;
        }
    }
    return (long)n;
}
