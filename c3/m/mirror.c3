module mirror;

const usz MAX_LENGTH = 256;
const usz MAX_INPUT_LENGTH = MAX_LENGTH + 1;

fn char* miroir(char* s) {
    usz n = 0;
    while (s[n] != 0) n++;
    if (n == 0) return s;
    usz i = 0, k = n - 1;
    while (i <= k) {
        char aux = s[i];
        s[i] = s[k];
        s[k] = aux;
        i++;
        if (k == 0) break;
        k--;
    }
    return s;
}

fn long mirror(long* input, usz length, char* output, usz capacity) @export("mirror") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_LENGTH) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 1 || input[i + 1] > 127) return -1;
    if (output == null || capacity < n + 1) return -2;
    char[MAX_INPUT_LENGTH] buffer = {0};
    for (usz i = 0; i < n; i++) buffer[i] = (char)input[i + 1];
    buffer[n] = 0;
    char* mirrored = miroir(&buffer[0]);
    for (usz i = 0; i < n; i++) output[i] = mirrored[i];
    output[n] = 0;
    return (long)n;
}
