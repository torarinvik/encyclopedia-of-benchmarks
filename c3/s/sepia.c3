module sepia;

const usz MIN_DIMENSION = 1;
const usz MAX_DIMENSION = 8;
const long MAX_FACTOR = 255;
const usz MAX_PIXELS = 64;
const usz MAX_VALID_INPUT_LENGTH = 195;
const usz MAX_PARSEABLE_INPUT_LENGTH = 196;
const usz MAX_OUTPUT_BYTES = 192;

fn double rounded_multiply(double left, double right) @noinline {
    return left * right;
}

fn double rounded_add(double left, double right) @noinline {
    return left + right;
}

fn bool allowed_channel(long value) {
    return value == 0 || value == 64 || value == 128 || value == 255;
}

fn long sepia(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("sepia") {
    if (input == null || input_length < 3 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < (long)MIN_DIMENSION || input[0] > (long)MAX_DIMENSION ||
        input[1] < (long)MIN_DIMENSION || input[1] > (long)MAX_DIMENSION ||
        input[2] < 0 || input[2] > MAX_FACTOR) return -1L;

    usz height = (usz)input[0];
    usz width = (usz)input[1];
    long factor = input[2];
    usz pixel_count = height * width;
    if (input_length != 3 + 3 * pixel_count || input_length > MAX_VALID_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < 3 * pixel_count; index++)
        if (!allowed_channel(input[3 + index])) return -1L;

    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz pixel = 0; pixel < pixel_count; pixel++) {
        double blue = (double)input[3 + 3 * pixel];
        double green = (double)input[3 + 3 * pixel + 1];
        double red = (double)input[3 + 3 * pixel + 2];
        double red_term = rounded_multiply(0.2126, red);
        double green_term = rounded_multiply(0.587, green);
        double blue_term = rounded_multiply(0.114, blue);
        double red_green_sum = rounded_add(red_term, green_term);
        double grayscale = rounded_add(red_green_sum, blue_term);
        long gray = (long)grayscale;
        long green_tinted = gray + factor;
        long red_tinted = gray + 2 * factor;
        staged[3 * pixel] = (uint8)gray;
        staged[3 * pixel + 1] = (uint8)(green_tinted < 255 ? green_tinted : 255);
        staged[3 * pixel + 2] = (uint8)(red_tinted < 255 ? red_tinted : 255);
    }

    usz output_bytes = 3 * pixel_count;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < output_bytes; index++) output[index] = staged[index];
    return (long)output_bytes;
}
