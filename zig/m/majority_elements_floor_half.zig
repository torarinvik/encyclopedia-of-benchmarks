const MAX_INPUT_LENGTH: usize = 256;
const TABLE_SIZE: usize = 512;
const TABLE_SIZE_I64: i64 = 512;

export fn majority_elements_floor_half(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (length > MAX_INPUT_LENGTH or (length != 0 and input == null)) return -1;
    const values = if (length == 0) &[_]i64{} else input.?[0..length];
    var keys: [TABLE_SIZE]i32 = @splat(0);
    var counts: [TABLE_SIZE]usize = @splat(0);
    var used: [TABLE_SIZE]bool = @splat(false);
    var order: [MAX_INPUT_LENGTH]usize = undefined;
    var unique_count: usize = 0;

    for (values) |value| {
        if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
        var remainder = @rem(value, TABLE_SIZE_I64);
        if (remainder < 0) remainder += TABLE_SIZE_I64;
        var slot: usize = @intCast(remainder);
        while (used[slot] and keys[slot] != @as(i32, @intCast(value))) {
            slot = (slot + 1) % TABLE_SIZE;
        }
        if (!used[slot]) {
            used[slot] = true;
            keys[slot] = @intCast(value);
            counts[slot] = 1;
            order[unique_count] = slot;
            unique_count += 1;
        } else {
            counts[slot] += 1;
        }
    }

    const threshold = length / 2;
    var result: [MAX_INPUT_LENGTH]i32 = @splat(0);
    var result_count: usize = 0;
    for (order[0..unique_count]) |slot| {
        if (counts[slot] >= threshold) {
            result[result_count] = keys[slot];
            result_count += 1;
        }
    }
    for (0..result_count) |index| {
        if (index == 0) continue;
        const value = result[index];
        var position = index;
        while (position > 0 and result[position - 1] > value) {
            result[position] = result[position - 1];
            position -= 1;
        }
        result[position] = value;
    }

    const required = result_count * 4;
    if (capacity < required or (required != 0 and output == null)) return -2;
    if (required != 0) {
        const bytes = output.?[0..capacity];
        for (result[0..result_count], 0..) |value, index| {
            const bits: u32 = @bitCast(value);
            for (0..4) |byte| bytes[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
        }
    }
    return @intCast(result_count);
}
