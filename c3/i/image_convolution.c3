module image_convolution;

const usz MAX_SIDE = 16;
const usz MAX_KERNEL_SIDE = 7;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long image_convolution(long* values, usz length, char* output, usz output_capacity)
    @export("image_convolution") {
    if (values == null || length < 3 || length > 308) return -1;
    long side_value = values[0];
    long kernel_side_value = values[1];
    if (side_value < 1 || side_value > (long)MAX_SIDE || kernel_side_value < 1 ||
        kernel_side_value > (long)MAX_KERNEL_SIDE || kernel_side_value % 2 == 0) return -1;
    usz side = (usz)side_value;
    usz kernel_side = (usz)kernel_side_value;
    usz pixel_count = side * side;
    usz kernel_count = kernel_side * kernel_side;
    if (length != 2 + pixel_count + kernel_count) return -1;
    for (usz index = 0; index < pixel_count; index++) {
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1;
    }
    for (usz index = 0; index < kernel_count; index++) {
        if (values[2 + pixel_count + index] < -16 || values[2 + pixel_count + index] > 16) return -1;
    }
    usz output_bytes = pixel_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    long radius = (long)(kernel_side / 2);
    for (usz row = 0; row < side; row++) {
        for (usz column = 0; column < side; column++) {
            long total = 0;
            for (usz kernel_row = 0; kernel_row < kernel_side; kernel_row++) {
                long source_row = (long)row + (long)kernel_row - radius;
                if (source_row < 0) source_row = 0;
                if (source_row >= (long)side) source_row = (long)side - 1;
                for (usz kernel_column = 0; kernel_column < kernel_side; kernel_column++) {
                    long source_column = (long)column + (long)kernel_column - radius;
                    if (source_column < 0) source_column = 0;
                    if (source_column >= (long)side) source_column = (long)side - 1;
                    long pixel = values[2 + (usz)source_row * side + (usz)source_column];
                    long weight = values[2 + pixel_count + kernel_row * kernel_side + kernel_column];
                    total += pixel * weight;
                }
            }
            store_i64_le(output, (row * side + column) * 8, total);
        }
    }
    return (long)output_bytes;
}
