module ema_filter;

fn void put_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

// Apply Java EMAFilter to one bounded sequence; alpha is quantized to 1/1024 steps.
fn long ema_filter(long* input, usz length, char* output, usz output_capacity) @export("ema_filter") {
    if (input == null || length < 2 || length > 7) return -1;
    long alpha_units = input[0], count_value = input[1];
    if (alpha_units < 1 || alpha_units > 1024 || count_value < 0 || count_value > 4 ||
        length != 2 + (usz)count_value) return -1;
    usz count = (usz)count_value;
    for (usz index = 0; index < count; index++)
        if (input[index + 2] < -1000000 || input[index + 2] > 1000000) return -1;
    usz required = count * 8;
    if (output_capacity < required || (required > 0 && output == null)) return -2;

    double alpha = (double)alpha_units / 1024.0;
    double ema_value = 0.0;
    for (usz index = 0; index < count; index++) {
        double sample = (double)input[index + 2];
        if (index == 0) ema_value = sample;
        else ema_value = alpha * sample + (1.0 - alpha) * ema_value;
        put_f64_le(output, index * 8, ema_value);
    }
    return (long)required;
}
