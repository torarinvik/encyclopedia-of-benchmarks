module sobel_filter;

extern fn double sqrt(double value);
extern fn double atan2(double y, double x);

const usz MIN_SIDE = 3;
const usz MAX_SIDE = 16;
const usz MAX_PARSEABLE_INPUT_LENGTH = 258;
const usz MAX_OUTPUT_ELEMENTS = 512;
const usz MAX_OUTPUT_BYTES = 4096;
const int[9] KERNEL_X = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
const int[9] KERNEL_Y = {1, 2, 1, 0, 0, 0, -1, -2, -1};

fn void write_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long sobel_filter(long* input, usz input_length, char* output, usz capacity) @export("sobel_filter") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < (long)MIN_SIDE || input[0] > (long)MAX_SIDE) return -1;
    usz side = (usz)input[0];
    usz pixel_count = side * side;
    if (input_length != pixel_count + 1) return -1;

    int[MAX_SIDE * MAX_SIDE] image;
    for (usz index = 0; index < pixel_count; index += 1) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
        image[index] = (int)input[index + 1];
    }
    int[MAX_SIDE * MAX_SIDE] gradient_x;
    int[MAX_SIDE * MAX_SIDE] gradient_y;
    int max_x = 0, max_y = 0;
    for (usz y = 0; y < side; y += 1) for (usz x = 0; x < side; x += 1) {
        int gx = 0, gy = 0;
        for (int ky = 0; ky < 3; ky += 1) {
            int sample_y = (int)y + ky - 1;
            if (sample_y < 0) sample_y = 0;
            if (sample_y >= (int)side) sample_y = (int)side - 1;
            for (int kx = 0; kx < 3; kx += 1) {
                int sample_x = (int)x + kx - 1;
                if (sample_x < 0) sample_x = 0;
                if (sample_x >= (int)side) sample_x = (int)side - 1;
                int pixel = image[(usz)sample_y * side + (usz)sample_x];
                usz kernel_index = (usz)(ky * 3 + kx);
                gx += pixel * KERNEL_X[kernel_index];
                gy += pixel * KERNEL_Y[kernel_index];
            }
        }
        if (gx < 0) gx = -gx;
        if (gy < 0) gy = -gy;
        usz index = y * side + x;
        gradient_x[index] = gx;
        gradient_y[index] = gy;
        if (gx > max_x) max_x = gx;
        if (gy > max_y) max_y = gy;
    }
    if (max_x == 0 || max_y == 0) return -1;

    double[MAX_SIDE * MAX_SIDE] scaled_x;
    double[MAX_SIDE * MAX_SIDE] scaled_y;
    double[MAX_SIDE * MAX_SIDE] magnitude;
    double[MAX_SIDE * MAX_SIDE] theta;
    double max_magnitude = 0.0;
    for (usz index = 0; index < pixel_count; index += 1) {
        scaled_x[index] = ((double)gradient_x[index] * 255.0) / (double)max_x;
        scaled_y[index] = ((double)gradient_y[index] * 255.0) / (double)max_y;
        magnitude[index] = sqrt((scaled_x[index] * scaled_x[index]) + (scaled_y[index] * scaled_y[index]));
        if (magnitude[index] > max_magnitude) max_magnitude = magnitude[index];
    }
    if (max_magnitude == 0.0) return -1;
    for (usz index = 0; index < pixel_count; index += 1) {
        double normalized = (magnitude[index] * 255.0) / max_magnitude;
        magnitude[index] = (double)(uint8)normalized;
        theta[index] = atan2(scaled_y[index], scaled_x[index]);
    }

    usz output_elements = 2 * pixel_count;
    usz output_bytes = output_elements * 8;
    if (output_elements > MAX_OUTPUT_ELEMENTS || output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < pixel_count; index += 1) {
        write_f64_le(magnitude[index], output, index * 8);
        write_f64_le(theta[index], output, (pixel_count + index) * 8);
    }
    return (long)output_elements;
}
