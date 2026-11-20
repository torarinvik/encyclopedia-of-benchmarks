module hough_line_transform;

const long MAX_HEIGHT = 8;
const long MAX_WIDTH = 8;
const usz MAX_CELLS = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 67;
const usz RHO_COUNT = 29;
const usz OUTPUT_BYTES = 116;

fn long hough_line_transform(long* input, usz length, char* output,
                             usz output_capacity) @export("hough_line_transform") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long height_value = input[0];
    long width_value = input[1];
    if (height_value < 1 || height_value > MAX_HEIGHT ||
        width_value < 1 || width_value > MAX_WIDTH) return -1;
    usz height = (usz)height_value;
    usz width = (usz)width_value;
    usz cells = height * width;
    if (length != 2 + cells) return -1;
    for (usz index = 0; index < cells; index++) {
        if (input[index + 2] != 0 && input[index + 2] != 1) return -1;
    }
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;

    char[OUTPUT_BYTES] accumulator = {};
    for (usz row = 0; row < height; row++) {
        for (usz column = 0; column < width; column++) {
            if (input[2 + row * width + column] == 0) continue;
            long x = (long)column;
            long y = (long)row;
            long[4] rho = {x, x + y, y, -x + y};
            for (usz angle = 0; angle < 4; angle++) {
                usz bin = angle * RHO_COUNT + (usz)(rho[angle] + 14);
                accumulator[bin]++;
            }
        }
    }
    for (usz index = 0; index < OUTPUT_BYTES; index++) output[index] = accumulator[index];
    return (long)OUTPUT_BYTES;
}
