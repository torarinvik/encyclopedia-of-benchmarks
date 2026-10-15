module z_algorithm;

const usz MAX_LENGTH = 2047;

fn long z_algorithm(long* input, usz length, char* output, usz output_capacity)
        @export("z_algorithm") {
    if (input == null || length < 1 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_LENGTH) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    usz output_bytes = count * 4;
    if (output_capacity < output_bytes || (count > 0 && output == null)) return -2;

    usz[MAX_LENGTH] z;
    for (usz index = 0; index < MAX_LENGTH; index++) z[index] = 0;
    usz left = 0, right = 0;
    for (usz index = 1; index < count; index++) {
        if (index < right) {
            usz reused = z[index - left];
            usz remaining = right - index;
            z[index] = reused < remaining ? reused : remaining;
        }
        while (index + z[index] < count && input[1 + z[index]] == input[1 + index + z[index]]) z[index]++;
        if (index + z[index] > right) {
            left = index;
            right = index + z[index];
        }
    }
    for (usz index = 0; index < count; index++) {
        for (usz byte = 0; byte < 4; byte++) output[index * 4 + byte] = (char)(z[index] >> (byte * 8));
    }
    return (long)count;
}
