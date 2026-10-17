module max_pooling;

const usz MAX_N = 16;
const usz MAX_INPUT_WORDS = 3 + MAX_N * MAX_N;
const usz MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1;
const usz MAX_OUTPUT_BYTES = 8 * MAX_N * MAX_N;

fn void put_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte += 1) { output[offset+byte] = (char)(bits & 255); bits >>= 8; }
}

long max_pooling(int* input, usz length, char* output, usz capacity) @export("max_pooling") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    int n = input[0], size = input[1], stride = input[2];
    if (n < 1 || n > 16 || size < 1 || size > n || stride < 1 || stride > 16 || length != (usz)(3+n*n)) return -1;
    for (usz i = 0; i < (usz)(n*n); i += 1) if (input[3+i] < -1000000 || input[3+i] > 1000000) return -1;
    int out_side = (n-size)/stride + 1;
    usz output_count = (usz)(out_side*out_side), bytes = output_count*8;
    if (output == null || capacity < bytes) return -2;
    char[2048] buffer;
    usz position = 0;
    for (int row = 0; row < out_side; row += 1) for (int col = 0; col < out_side; col += 1) {
        int start_row = row*stride, start_col = col*stride;
        int maximum = input[3+start_row*n+start_col];
        for (int r = 0; r < size; r += 1) for (int c = 0; c < size; c += 1) {
            int value = input[3+(start_row+r)*n+start_col+c];
            if (value > maximum) maximum = value;
        }
        put_f64_le(&buffer[0], position, (double)maximum);
        position += 8;
    }
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
