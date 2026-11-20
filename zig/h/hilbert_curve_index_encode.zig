const MAX_ORDER: i64 = 8;

fn hilbertIndex(order: i64, x_value: i64, y_value: i64) i64 {
    var current_x = x_value;
    var current_y = y_value;
    var distance: i64 = 0;
    var bit_index = order - 1;
    while (bit_index >= 0) : (bit_index -= 1) {
        const bit: i64 = @as(i64, 1) << @intCast(bit_index);
        const x_bit: i64 = @intFromBool((current_x & bit) != 0);
        const y_bit: i64 = @intFromBool((current_y & bit) != 0);
        distance += bit * bit * ((3 * x_bit) ^ y_bit);
        const mask = bit - 1;
        var low_x = current_x & mask;
        var low_y = current_y & mask;
        if (y_bit == 0) {
            if (x_bit != 0) {
                low_x = mask - low_x;
                low_y = mask - low_y;
            }
            current_x = low_y;
            current_y = low_x;
        } else {
            current_x = low_x;
            current_y = low_y;
        }
    }
    return distance;
}

fn storeI64Le(output: [*]u8, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn hilbert_curve_index_encode(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?[0..length];
    const order = values[0];
    if (order < 1 or order > MAX_ORDER) return -1;
    const side: i64 = @as(i64, 1) << @intCast(order);
    const x = values[1];
    const y = values[2];
    if (x < 0 or x >= side or y < 0 or y >= side) return -1;
    if (output == null or capacity < 8) return -2;
    storeI64Le(output.?, hilbertIndex(order, x, y));
    return 8;
}
