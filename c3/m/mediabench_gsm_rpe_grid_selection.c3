module mediabench_gsm_rpe_grid_selection;

const usz INPUT_COUNT = 40;
const usz MAX_INPUT_LENGTH = 41;
const usz OUTPUT_BYTES = 112;

fn long asr2(long value) {
    return value >= 0 ? value / 4 : -(((-value) + 3) / 4);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long mediabench_gsm_rpe_grid_selection(long* input, usz input_length,
                                         char* output, usz output_capacity)
    @export("mediabench_gsm_rpe_grid_selection")
{
    if (input == null || input_length == 0 || input_length > MAX_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) if (input[i] < -32768 || input[i] > 32767) return -1;
    if (input_length != INPUT_COUNT) return -1;

    long best_score = -1, best_grid = 0;
    for (long grid = 0; grid < 4; grid++) {
        long sum = 0;
        for (long i = 0; i < 13; i++) {
            long scaled = asr2(input[grid + 3 * i]);
            sum += scaled * scaled;
        }
        long score = 2 * sum;
        if (score > best_score) { best_score = score; best_grid = grid; }
    }
    long[14] staged;
    staged[0] = best_grid;
    for (long i = 0; i < 13; i++) staged[1 + i] = input[best_grid + 3 * i];
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;
    for (usz i = 0; i < 14; i++) store_i64_le(output, 8 * i, staged[i]);
    return (long)OUTPUT_BYTES;
}
