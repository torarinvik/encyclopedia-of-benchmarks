// Independently written bounded IJG h2v2 adaptation; see package README/LICENSE.
module cbench_consumer_jpeg_h2v2_fancy_upsample;

const int MAX_WIDTH = 16;
const int MAX_HEIGHT = 8;
const int MAX_PIXELS = 128;
const int MAX_OUTPUT = 512;

fn long cbench_consumer_jpeg_h2v2_fancy_upsample(long* input, usz length,
    u8* output, usz capacity) @export("cbench_consumer_jpeg_h2v2_fancy_upsample") {
    if (input == null || length < 5 || length > 131) return -1;
    if (input[0] < 3 || input[0] > MAX_WIDTH || input[1] < 1 || input[1] > MAX_HEIGHT) return -1;
    usz width = input[0].usz();
    usz height = input[1].usz();
    usz pixels = width * height;
    if (length != 2 + pixels) return -1;
    for (usz i = 0; i < pixels; i++) if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    usz output_size = 4 * pixels;
    if (output == null || capacity < output_size) return -2;
    u8 staged[MAX_OUTPUT] = {0};
    usz p = 0;
    for (usz y = 0; y < height; y++) {
        for (int v = 0; v < 2; v++) {
            usz far_y = v == 0 ? (y == 0 ? 0 : y - 1) : (y + 1 == height ? y : y + 1);
            int sums[MAX_WIDTH] = {0};
            for (usz x = 0; x < width; x++) sums[x] = 3 * input[2 + y * width + x].int() + input[2 + far_y * width + x].int();
            staged[p] = ((sums[0] * 4 + 8) >> 4).u8(); p++;
            staged[p] = ((sums[0] * 3 + sums[1] + 7) >> 4).u8(); p++;
            for (usz x = 1; x + 1 < width; x++) {
                staged[p] = ((sums[x] * 3 + sums[x - 1] + 8) >> 4).u8(); p++;
                staged[p] = ((sums[x] * 3 + sums[x + 1] + 7) >> 4).u8(); p++;
            }
            staged[p] = ((sums[width - 1] * 3 + sums[width - 2] + 8) >> 4).u8(); p++;
            staged[p] = ((sums[width - 1] * 4 + 7) >> 4).u8(); p++;
        }
    }
    for (usz i = 0; i < output_size; i++) output[i] = staged[i];
    return output_size.long();
}
