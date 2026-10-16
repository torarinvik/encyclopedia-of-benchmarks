module bilateral_filter;

extern fn double exp(double value);
const long MAX_SIDE = 32;
const long MAX_PIXELS = MAX_SIDE * MAX_SIDE;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits >> (8 * byte)); }
}

fn long bilateral_filter(long* values, usz length, char* output, usz output_capacity)
        @export("bilateral_filter") {
    if (values == null || length < 5 || length > (usz)(5 + MAX_PIXELS)) return -1;
    long height_value = values[0];
    long width_value = values[1];
    long kernel_value = values[2];
    long spatial_q = values[3];
    long intensity_q = values[4];
    if (height_value < 1 || height_value > MAX_SIDE || width_value < 1 || width_value > MAX_SIDE ||
        (kernel_value != 1 && kernel_value != 3 && kernel_value != 5 && kernel_value != 7) ||
        spatial_q < 1 || spatial_q > 1000000 || intensity_q < 1 || intensity_q > 1000000) return -1;
    usz height = (usz)height_value;
    usz width = (usz)width_value;
    usz pixels = height * width;
    if (length != 5 + pixels) return -1;
    for (usz i = 0; i < pixels; i++) if (values[5 + i] < 0 || values[5 + i] > 1000000) return -1;
    usz required = pixels * 8;
    if (output == null || output_capacity < required) return -2;

    usz kernel_size = (usz)kernel_value;
    usz radius = kernel_size / 2;
    double spatial_variance = (double)spatial_q / 1000000.0;
    double intensity_variance = (double)intensity_q / 1000000.0;
    long[MAX_PIXELS] filtered;
    for (usz i = 0; i < pixels; i++) filtered[i] = 0;
    if (height >= kernel_size && width >= kernel_size) {
        for (usz row = radius; row < height - radius; row++) {
            for (usz column = radius; column < width - radius; column++) {
                double center = (double)values[5 + row * width + column] / 1000000.0;
                double weighted_sum = 0.0;
                double weight_sum = 0.0;
                for (long dy = -(long)radius; dy <= (long)radius; dy++) {
                    for (long dx = -(long)radius; dx <= (long)radius; dx++) {
                        usz sample_index = (usz)((long)row + dy) * width + (usz)((long)column + dx);
                        double sample = (double)values[5 + sample_index] / 1000000.0;
                        double distance_squared = (double)(dx * dx + dy * dy);
                        double difference = sample - center;
                        double weight = exp(-distance_squared / (2.0 * spatial_variance));
                        weight *= exp(-(difference * difference) / (2.0 * intensity_variance));
                        weighted_sum += sample * weight;
                        weight_sum += weight;
                    }
                }
                filtered[row * width + column] = (long)(weighted_sum / weight_sum * 1000000.0 + 0.5);
            }
        }
    }
    for (usz i = 0; i < pixels; i++) write_i64_le(output, i * 8, filtered[i]);
    return (long)required;
}
