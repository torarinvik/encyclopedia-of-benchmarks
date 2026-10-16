module flip_augmentation;

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long flip_augmentation(long* values, usz length, char* output, usz output_capacity)
        @export("flip_augmentation") {
    if (values == null || length < 4 || length > 340) return -1;
    if (values[0] < 1 || values[0] > 16 || values[1] < 1 || values[1] > 16 ||
        (values[2] != 0 && values[2] != 1) || values[3] < 0 || values[3] > 16) return -1;
    usz width = (usz)values[0];
    usz height = (usz)values[1];
    usz flip_type = (usz)values[2];
    usz box_count = (usz)values[3];
    usz pixel_count = width * height;
    if (length != 4 + pixel_count + 5 * box_count) return -1;
    for (usz index = 0; index < pixel_count; index++)
        if (values[4 + index] < 0 || values[4 + index] > 255) return -1;
    for (usz box = 0; box < box_count; box++) {
        usz base = 4 + pixel_count + 5 * box;
        if (values[base] < 0 || values[base] > 2147483647) return -1;
        for (usz field = 1; field < 5; field++)
            if (values[base + field] < 0 || values[base + field] > 1000000) return -1;
    }
    usz output_bytes = pixel_count + 20 * box_count;
    if (output == null || output_capacity < output_bytes) return -2;

    for (usz row = 0; row < height; row++) {
        for (usz column = 0; column < width; column++) {
            usz source_row = flip_type == 0 ? height - 1 - row : row;
            usz source_column = flip_type == 1 ? width - 1 - column : column;
            output[row * width + column] = (char)values[4 + source_row * width + source_column];
        }
    }
    for (usz box = 0; box < box_count; box++) {
        usz base = 4 + pixel_count + 5 * box;
        usz output_base = pixel_count + 20 * box;
        for (usz field = 0; field < 5; field++) {
            long value = values[base + field];
            if (flip_type == 1 && field == 1) value = 1000000 - value;
            if (flip_type == 0 && field == 2) value = 1000000 - value;
            store_i32_le(output, output_base + 4 * field, value);
        }
    }
    return (long)output_bytes;
}
