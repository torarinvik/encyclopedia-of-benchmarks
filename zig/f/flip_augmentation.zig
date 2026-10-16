const MAX_INPUT_LENGTH: usize = 340;
const COORDINATE_SCALE: i64 = 1_000_000;

fn store_i32_le(output: [*]u8, position: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

/// Flip grayscale pixels and reflect normalized bounding-box centers.
export fn flip_augmentation(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 1 or values[0] > 16 or values[1] < 1 or values[1] > 16) return -1;
    if ((values[2] != 0 and values[2] != 1) or values[3] < 0 or values[3] > 16) return -1;
    const width: usize = @intCast(values[0]);
    const height: usize = @intCast(values[1]);
    const flip_type: usize = @intCast(values[2]);
    const box_count: usize = @intCast(values[3]);
    const pixel_count = width * height;
    if (length != 4 + pixel_count + 5 * box_count) return -1;
    for (0..pixel_count) |index| {
        if (values[4 + index] < 0 or values[4 + index] > 255) return -1;
    }
    for (0..box_count) |box| {
        const base = 4 + pixel_count + 5 * box;
        if (values[base] < 0 or values[base] > 2147483647) return -1;
        for (1..5) |field| {
            if (values[base + field] < 0 or values[base + field] > COORDINATE_SCALE) return -1;
        }
    }
    const output_bytes = pixel_count + 20 * box_count;
    if (output == null or output_capacity < output_bytes) return -2;

    for (0..height) |row| {
        for (0..width) |column| {
            const source_row = if (flip_type == 0) height - 1 - row else row;
            const source_column = if (flip_type == 1) width - 1 - column else column;
            output[row * width + column] = @intCast(values[4 + source_row * width + source_column]);
        }
    }
    for (0..box_count) |box| {
        const base = 4 + pixel_count + 5 * box;
        const output_base = pixel_count + 20 * box;
        for (0..5) |field| {
            var value = values[base + field];
            if (flip_type == 1 and field == 1) value = COORDINATE_SCALE - value;
            if (flip_type == 0 and field == 2) value = COORDINATE_SCALE - value;
            store_i32_le(output, output_base + 4 * field, @intCast(value));
        }
    }
    return @intCast(output_bytes);
}
