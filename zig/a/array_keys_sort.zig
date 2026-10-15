fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
}
fn compareRows(left: *[4]i64, right: *[4]i64, keys: *[4]i64, key_count: usize, ascending: bool) i32 {
    for (0..key_count) |index| {
        const field: usize = @intCast(keys.*[index] - 1);
        if (left.*[field] < right.*[field]) return if (ascending) -1 else 1;
        if (left.*[field] > right.*[field]) return if (ascending) 1 else -1;
    }
    return 0;
}
export fn array_keys_sort(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 8 or length > 263) return -1;
    const input = values.?[0..length];
    const raw_count = input[0]; const raw_key_count = input[1]; const order = input[2];
    if (raw_count < 1 or raw_count > 64 or raw_key_count < 1 or raw_key_count > 4 or (order != 0 and order != 1)) return -1;
    const count: usize = @intCast(raw_count); const key_count: usize = @intCast(raw_key_count);
    if (length != 3 + key_count + 4 * count) return -1;
    var keys: [4]i64 = @splat(0);
    for (0..key_count) |index| {
        const key = input[index + 3];
        if (key < 1 or key > 4) return -1;
        for (0..index) |previous| if (keys[previous] == key) return -1;
        keys[index] = key;
    }
    var rows: [256]i64 = @splat(0);
    const rows_start = 3 + key_count;
    for (0..4 * count) |index| {
        const value = input[rows_start + index];
        if (value < -1000 or value > 1000) return -1;
        rows[index] = value;
    }
    for (0..count) |left| {
        for (left + 1..count) |right| {
            if (compareRows(@ptrCast(&rows[left * 4]), @ptrCast(&rows[right * 4]), &keys, key_count, true) == 0) return -1;
        }
    }
    const byte_count = 32 * count;
    if (output == null or output_capacity < byte_count) return -2;
    for (1..count) |index| {
        var temporary: [4]i64 = undefined;
        @memcpy(&temporary, rows[index * 4 ..][0..4]);
        var position = index;
        while (position > 0 and compareRows(@ptrCast(&rows[(position - 1) * 4]), &temporary, &keys, key_count, order == 1) > 0) {
            @memcpy(rows[position * 4 ..][0..4], rows[(position - 1) * 4 ..][0..4]);
            position -= 1;
        }
        @memcpy(rows[position * 4 ..][0..4], &temporary);
    }
    for (0..4 * count) |index| storeI64Le(output.?, 8 * index, rows[index]);
    return @intCast(byte_count);
}
