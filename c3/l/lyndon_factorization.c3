module lyndon_factorization;
const usz MAX_SEQUENCE_LENGTH = 256;

fn long lyndon_factorization(long* input, usz length, char* output, usz capacity) @export("lyndon_factorization") {
    if (length < 1 || length > MAX_SEQUENCE_LENGTH + 1 || input == null) return -1;
    if (input[0] < 0 || input[0] > MAX_SEQUENCE_LENGTH || length != (usz)input[0] + 1) return -1;
    usz n = (usz)input[0];
    for (usz i = 0; i < n; i++) if (input[i + 1] < 97 || input[i + 1] > 122) return -1;
    usz required = 2 * n;
    if (capacity < required || (required != 0 && output == null)) return -2;
    usz start = 0, out = 0;
    while (start < n) {
        usz candidate = start + 1, matched = start;
        while (candidate < n && input[matched + 1] <= input[candidate + 1]) {
            if (input[matched + 1] < input[candidate + 1]) matched = start; else matched++;
            candidate++;
        }
        usz factor_length = candidate - matched;
        while (start <= matched) {
            for (usz j = 0; j < factor_length; j++) { output[out++] = (char)(uint)input[start + j + 1]; }
            output[out++] = 0;
            start += factor_length;
        }
    }
    return (long)out;
}
