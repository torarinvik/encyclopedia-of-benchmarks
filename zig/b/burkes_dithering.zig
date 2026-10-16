fn truncDiv32(value: i32) i32 {
    if (value < 0) return -@divTrunc(-value, 32);
    return @divTrunc(value, 32);
}

export fn burkes_dithering(input: ?[*]const i64, length: usize) i64 {
    if (length < 3 or length > 150 or input == null) return -1;
    const values = input.?;
    if (values[0] < 1 or values[0] > 7 or values[1] < 1 or values[1] > 254) return -1;
    const side: usize = @intCast(values[0]);
    const threshold: i32 = @intCast(values[1]);
    if (length != 2 + 3 * side * side) return -1;
    for (2..length) |index| {
        if (values[index] < 0 or values[index] > 255) return -1;
    }

    const stride = side + 4;
    var errors: [8 * 11]i32 = @splat(0);
    var white_pixels: u64 = 0;
    for (0..side) |y| {
        for (0..side) |x| {
            const offset = 2 + 3 * (y * side + x);
            const blue: i32 = @intCast(values[offset]);
            const green: i32 = @intCast(values[offset + 1]);
            const red: i32 = @intCast(values[offset + 2]);
            const gray = @divTrunc(114 * blue + 587 * green + 299 * red, 1000);
            const adjusted = gray + errors[y * stride + x];
            const white = adjusted >= threshold;
            const current_error = adjusted - (if (white) @as(i32, 255) else 0);
            if (white) white_pixels |= @as(u64, 1) << @intCast(y * side + x);
            errors[y * stride + x + 1] += truncDiv32(8 * current_error);
            errors[y * stride + x + 2] += truncDiv32(4 * current_error);
            errors[(y + 1) * stride + x] += truncDiv32(8 * current_error);
            errors[(y + 1) * stride + x + 1] += truncDiv32(4 * current_error);
            errors[(y + 1) * stride + x + 2] += truncDiv32(2 * current_error);
            if (x >= 1) errors[(y + 1) * stride + x - 1] += truncDiv32(4 * current_error);
            if (x >= 2) errors[(y + 1) * stride + x - 2] += truncDiv32(2 * current_error);
        }
    }
    return @intCast(white_pixels);
}
