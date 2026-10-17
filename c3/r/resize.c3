module resize;

const usz MAX_INPUT_LENGTH = 3077;
const usz MAX_OUTPUT_BYTES = 3072;

fn long resize(long* input, usz length, char* output, usz capacity) @export("resize") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long src_width = input[0], src_height = input[1], dst_width = input[2], dst_height = input[3];
    if (src_width < 1 || src_width > 32 || src_height < 1 || src_height > 32 ||
        dst_width < 1 || dst_width > 32 || dst_height < 1 || dst_height > 32) return -1;

    usz expected_length = 4 + 3 * (usz)src_width * (usz)src_height;
    if (length != expected_length) return -1;
    for (usz i = 4; i < expected_length; i++) {
        if (input[i] < 0 || input[i] > 255) return -1;
    }

    usz needed = 3 * (usz)dst_width * (usz)dst_height;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < needed) return -2;

    double ratio_x = (double)src_width / (double)dst_width;
    double ratio_y = (double)src_height / (double)dst_height;
    usz out = 0;
    for (usz y = 0; y < (usz)dst_height; y++) {
        usz src_y = (usz)(ratio_y * (double)y);
        for (usz x = 0; x < (usz)dst_width; x++) {
            usz src_x = (usz)(ratio_x * (double)x);
            usz src = 4 + 3 * (src_y * (usz)src_width + src_x);
            output[out++] = (char)input[src];
            output[out++] = (char)input[src + 1];
            output[out++] = (char)input[src + 2];
        }
    }
    return (long)needed;
}
