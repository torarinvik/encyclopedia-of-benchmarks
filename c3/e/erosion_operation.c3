module erosion_operation;
fn long erosion_operation(long *input, usz length) @export("erosion_operation") {
    if (input == null || length < 2 || length > 38) return -1;
    long height = input[0], width = input[1];
    if (height < 1 || height > 6 || width < 1 || width > 6 || length != 2 + (usz)(height * width)) return -1;
    for (usz i = 2; i < length; i++) if (input[i] != 0 && input[i] != 1) return -1;
    long result = 0;
    for (long row = 0; row < height; row++) for (long col = 0; col < width; col++) {
        bool keep = input[2 + row * width + col] == 1;
        if (row == 0 || input[2 + (row - 1) * width + col] != 1) keep = false;
        if (row + 1 == height || input[2 + (row + 1) * width + col] != 1) keep = false;
        if (col == 0 || input[2 + row * width + col - 1] != 1) keep = false;
        if (col + 1 == width || input[2 + row * width + col + 1] != 1) keep = false;
        if (keep) result |= 1L << (row * width + col);
    }
    return result;
}
