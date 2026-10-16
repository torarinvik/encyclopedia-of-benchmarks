module mean_threshold;

const usz MAX_PARSEABLE_INPUT_LENGTH = 1027;
const long MAX_DIMENSION = 32;

fn long mean_threshold(long* input, usz length, uint8* output, usz output_capacity) @export("mean_threshold") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_DIMENSION || input[1] < 1 || input[1] > MAX_DIMENSION) return -1;

    usz width = (usz)input[0];
    usz height = (usz)input[1];
    usz pixel_count = width * height;
    if (length != pixel_count + 2) return -1;

    long sum = 0;
    for (usz i = 0; i < pixel_count; i++) {
        long pixel = input[2 + i];
        if (pixel < 0 || pixel > 255) return -1;
        sum += pixel;
    }

    long mean = sum / (long)pixel_count;
    if (output_capacity < pixel_count || output == null) return -2;
    for (usz i = 0; i < pixel_count; i++) {
        if (input[2 + i] > mean) output[i] = 255;
        else output[i] = 0;
    }
    return (long)pixel_count;
}

