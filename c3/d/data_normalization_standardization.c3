module data_normalization_standardization;

const usz MAX_SAMPLE_COUNT = 128;
extern fn double sqrt(double value);

fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long data_normalization_standardization(long* values, usz length, char* output,
                                           usz capacity) @export("data_normalization_standardization") {
    if (values == null || length < 4 || length > MAX_SAMPLE_COUNT + 2) return -1;
    long mode = values[0];
    long count_arg = values[1];
    if ((mode != 0 && mode != 1) || count_arg < 2 || count_arg > (long)MAX_SAMPLE_COUNT ||
        length != (usz)count_arg + 2) return -1;
    usz count = (usz)count_arg;
    long minimum = values[2];
    long maximum = values[2];
    double sum = 0.0;
    for (usz index = 0; index < count; index++) {
        long value = values[index + 2];
        if (value < -100000 || value > 100000) return -1;
        if (value < minimum) minimum = value;
        if (value > maximum) maximum = value;
        sum += (double)value;
    }
    if (minimum == maximum) return -1;
    usz output_bytes = count * 8;
    if (output == null || capacity < output_bytes) return -2;
    if (mode == 0) {
        double span = (double)(maximum - minimum);
        for (usz index = 0; index < count; index++) {
            double normalized = ((double)values[index + 2] - (double)minimum) / span;
            put_f64_le(normalized, output, index * 8);
        }
    } else {
        double mean = sum / (double)count;
        double squared_deviations = 0.0;
        for (usz index = 0; index < count; index++) {
            double deviation = (double)values[index + 2] - mean;
            squared_deviations += deviation * deviation;
        }
        double sample_deviation = sqrt(squared_deviations / (double)(count - 1));
        for (usz index = 0; index < count; index++) {
            double standardized = ((double)values[index + 2] - mean) / sample_deviation;
            put_f64_le(standardized, output, index * 8);
        }
    }
    return (long)output_bytes;
}
