module mean_threshold;

const usz MAX_PARSEABLE_INPUT_LENGTH = 1026;
const long MAX_SIDE_LENGTH = 32;

fn long mean_threshold(long* input, usz length, uint8* output, usz output_capacity) @export("mean_threshold") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_SIDE_LENGTH) return -1;

    usz side = (usz)input[0];
    usz pixel_count = side * side;
    if (length != pixel_count + 1) return -1;

    long sum = 0;
    for (usz i = 0; i < pixel_count; i++) {
        long pixel = input[1 + i];
        if (pixel < 0 || pixel > 255) return -1;
        sum += pixel;
    }

    long mean = sum / (long)pixel_count;
    if (output_capacity < pixel_count || output == null) return -2;
    for (usz i = 0; i < pixel_count; i++) {
        if (input[1 + i] > mean) output[i] = 255;
        else output[i] = 0;
    }
    return (long)pixel_count;
}

