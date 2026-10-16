module convolve_1d;

const usz MAX_SIGNAL_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_SIGNAL_LENGTH;
const usz MAX_OUTPUT_BYTES = MAX_SIGNAL_LENGTH * 8;
const long MAX_FIXED_SAMPLE = 128;
const double SAMPLE_SCALE = 16.0;

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long convolve_1d(long* input, usz length, char* output, usz output_capacity)
    @export("convolve_1d") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_signal_count = input[0];
    long raw_kernel_count = input[1];
    if (raw_signal_count < 0 || raw_signal_count > (long)MAX_SIGNAL_LENGTH ||
        raw_kernel_count < 0 || raw_kernel_count > (long)MAX_SIGNAL_LENGTH) return -1;
    usz signal_count = (usz)raw_signal_count;
    usz kernel_count = (usz)raw_kernel_count;
    if (length != 2 + signal_count + kernel_count) return -1;
    for (usz index = 0; index < signal_count + kernel_count; index++) {
        long value = input[index + 2];
        if (value < -MAX_FIXED_SAMPLE || value > MAX_FIXED_SAMPLE) return -1;
    }

    usz output_bytes = signal_count * 8;
    if (output_capacity < output_bytes || (output_bytes > 0 && output == null)) return -2;
    usz center = kernel_count / 2;
    for (usz i = 0; i < signal_count; i++) {
        double accumulated = 0.0;
        for (usz j = 0; j < kernel_count; j++) {
            long signal_index = (long)i + (long)j - (long)center;
            if (signal_index >= 0 && signal_index < (long)signal_count) {
                double kernel_value = (double)input[2 + signal_count + j] / SAMPLE_SCALE;
                double signal_value = (double)input[2 + (usz)signal_index] / SAMPLE_SCALE;
                accumulated += kernel_value * signal_value;
            }
        }
        write_f64_le(accumulated, output, i * 8);
    }
    return (long)output_bytes;
}
