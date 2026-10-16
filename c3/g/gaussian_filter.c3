module gaussian_filter;

const long GAUSSIAN_SCALE = 1000000000000000;

fn long gaussian_filter_weight(long kernel_size, long distance) {
    if (kernel_size == 3) {
        if (distance == 0) return 159154943091895;
        if (distance == 1) return 96532352630054;
        return 58549831524319;
    }
    if (distance == 0) return 198943678864869;
    if (distance == 1) return 91083053297916;
    if (distance == 2) return 41700860491808;
    if (distance == 4) return 8740975213082;
    if (distance == 5) return 4001910066968;
    return 384051647741;
}

fn long gaussian_filter(long *values, usz length, char *output, usz capacity) @export("gaussian_filter") {
    if (values == null || length < 3) return -1;
    long height = values[0], width = values[1], kernel_size = values[2];
    if (height < 3 || height > 12 || width < 3 || width > 12
            || (kernel_size != 3 && kernel_size != 5)
            || height < kernel_size || width < kernel_size
            || length != 3 + (usz)(height * width)) return -1;
    for (usz index = 3; index < length; index++) {
        if (values[index] < 0 || values[index] > 255) return -1;
    }

    usz output_height = (usz)(height - kernel_size + 1);
    usz output_width = (usz)(width - kernel_size + 1);
    usz output_count = output_height * output_width;
    if (capacity < output_count || output == null) return -2;

    long center = kernel_size / 2;
    for (usz row = 0; row < output_height; row++) {
        for (usz column = 0; column < output_width; column++) {
            long total = 0;
            for (long kernel_row = 0; kernel_row < kernel_size; kernel_row++) {
                long dy = kernel_row - center;
                for (long kernel_column = 0; kernel_column < kernel_size; kernel_column++) {
                    long dx = kernel_column - center;
                    usz pixel_index = 3 + (row + (usz)kernel_row) * (usz)width
                                      + column + (usz)kernel_column;
                    total += values[pixel_index]
                             * gaussian_filter_weight(kernel_size, dx * dx + dy * dy);
                }
            }
            output[row * output_width + column] = (char)(total / GAUSSIAN_SCALE);
        }
    }
    return (long)output_count;
}
