module burkes_dithering;

fn int trunc_div32(int value) {
    return value < 0 ? -((-value) / 32) : value / 32;
}

fn long burkes_dithering(long* input, usz length) @export("burkes_dithering") {
    if (input == null || length < 3 || length > 150) return -1;
    if (input[0] < 1 || input[0] > 7 || input[1] < 1 || input[1] > 254) return -1;
    usz side = (usz)input[0];
    int threshold = (int)input[1];
    if (length != 2 + 3 * side * side) return -1;
    for (usz index = 2; index < length; index++) {
        if (input[index] < 0 || input[index] > 255) return -1;
    }

    usz stride = side + 4;
    int[88] errors;
    for (usz index = 0; index < 88; index++) errors[index] = 0;
    ulong white_pixels = 0;
    for (usz y = 0; y < side; y++) {
        for (usz x = 0; x < side; x++) {
            usz offset = 2 + 3 * (y * side + x);
            int blue = (int)input[offset];
            int green = (int)input[offset + 1];
            int red = (int)input[offset + 2];
            int gray = (114 * blue + 587 * green + 299 * red) / 1000;
            int adjusted = gray + errors[y * stride + x];
            bool white = adjusted >= threshold;
            int current_error = adjusted - (white ? 255 : 0);
            if (white) white_pixels |= 1ul << (ulong)(y * side + x);
            errors[y * stride + x + 1] += trunc_div32(8 * current_error);
            errors[y * stride + x + 2] += trunc_div32(4 * current_error);
            errors[(y + 1) * stride + x] += trunc_div32(8 * current_error);
            errors[(y + 1) * stride + x + 1] += trunc_div32(4 * current_error);
            errors[(y + 1) * stride + x + 2] += trunc_div32(2 * current_error);
            if (x >= 1) errors[(y + 1) * stride + x - 1] += trunc_div32(4 * current_error);
            if (x >= 2) errors[(y + 1) * stride + x - 2] += trunc_div32(2 * current_error);
        }
    }
    return (long)white_pixels;
}
