module rotate_to_the_right;

const usz MAX_N = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_N + 4;
const usz MAX_OUTPUT_BYTES = 8 * MAX_N;
const long MAX_PLACES = 1000000;

fn long rotate_to_the_right(long* input, usz length, char* output, usz output_capacity)
        @export("rotate_to_the_right") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long places = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || places < -MAX_PLACES || places > MAX_PLACES) return -1;
    usz n = (usz)n_value;
    if (length != n + 2) return -1;
    for (usz index = 0; index < n; index++)
        if (input[2 + index] < -2147483648 || input[2 + index] > 2147483647) return -1;

    long remainder = places % n_value;
    usz shift = (usz)(remainder < 0 ? remainder + n_value : remainder);
    usz output_bytes = n * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    char[MAX_OUTPUT_BYTES] encoded;
    for (usz index = 0; index < n; index++) {
        usz source = (index + n - shift) % n;
        ulong bits = (ulong)input[2 + source];
        for (usz byte = 0; byte < 8; byte++) {
            encoded[index * 8 + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    for (usz index = 0; index < output_bytes; index++) output[index] = encoded[index];
    return (long)output_bytes;
}
