const MIN_CAPACITY: usize = 5;
const MAX_CAPACITY: usize = 31;
const MAX_INSERT_COUNT: i64 = 3;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 5;
const MAX_OUTPUT_BYTES: usize = 256;

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn quadratic_probing(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const capacity_value = input[0];
    const count_value = input[1];
    if (capacity_value < MIN_CAPACITY or capacity_value > MAX_CAPACITY or count_value < 0 or count_value > MAX_INSERT_COUNT) return -1;
    const capacity: usize = @intCast(capacity_value);
    const insert_count: usize = @intCast(count_value);
    if (input_length != 2 + insert_count) return -1;
    for (0..insert_count) |index| {
        if (input[index + 2] < 0) return -1;
    }

    var slots = [_]i64{-1} ** MAX_CAPACITY;
    for (0..insert_count) |key_index| {
        const key = input[key_index + 2];
        const home: usize = @intCast(@mod(key, @as(i64, @intCast(capacity))));
        if (slots[home] == -1) {
            slots[home] = key;
            continue;
        }
        if (slots[home] == key) continue;
        var visited = [_]bool{false} ** MAX_CAPACITY;
        var probe: usize = 1;
        while (true) : (probe += 1) {
            const slot = (home + probe * probe) % capacity;
            if (slots[slot] == -1 or slots[slot] == @as(i64, @intCast(home))) {
                slots[slot] = key;
                break;
            }
            if (visited[slot]) return -1;
            visited[slot] = true;
        }
    }

    const byte_length = 8 * (capacity + 1);
    if (byte_length > MAX_OUTPUT_BYTES or output == null or output_capacity < byte_length) return -2;
    putI64Le(output, 0, @intCast(capacity));
    for (0..capacity) |index| putI64Le(output, 8 * (index + 1), slots[index]);
    return @intCast(byte_length);
}
