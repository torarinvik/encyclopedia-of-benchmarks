module change_brightness;

fn long truncate_divide(long numerator, long denominator) {
    if (numerator < 0) return -((-numerator) / denominator);
    return numerator / denominator;
}
fn long transform_channel(long channel, long level, long mode) {
    long value;
    if (mode == 0) {
        value = channel + level;
    } else {
        long denominator = 255 * (259 - level);
        long numerator = 128 * denominator + 259 * (level + 255) * (channel - 128);
        value = truncate_divide(numerator, denominator);
    }
    if (value < 0) return 0;
    if (value > 255) return 255;
    return value;
}
fn long image_point_transform(long* values, usz length, char* output, usz output_capacity, long mode) {
    if (values == null || length < 1 || length > 4096) return -1;
    long level = values[0];
    if (level < -255 || level > 255) return -1;
    usz channels = length - 1;
    for (usz index = 0; index < channels; index++) {
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;
    }
    if (channels > output_capacity || (channels != 0 && output == null)) return -2;
    for (usz index = 0; index < channels; index++) {
        output[index] = (char)transform_channel(values[index + 1], level, mode);
    }
    return (long)channels;
}
fn long change_brightness(long* values, usz length, char* output, usz output_capacity) @export("change_brightness") {
    return image_point_transform(values, length, output, output_capacity, 0);
}
fn long change_contrast(long* values, usz length, char* output, usz output_capacity) @export("change_contrast") {
    return image_point_transform(values, length, output, output_capacity, 1);
}
