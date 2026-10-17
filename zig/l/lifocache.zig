fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |i| output[offset + i] = @truncate(bytes >> @as(u6, @intCast(8 * i)));
}

export fn lifocache(input: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > 194) return -1;
    const capacity_value = input[0];
    const operation_count_value = input[1];
    if (capacity_value < 1 or capacity_value > 16 or operation_count_value < 1 or operation_count_value > 64) return -1;
    const capacity: usize = @intCast(capacity_value);
    const operations: usize = @intCast(operation_count_value);
    if (length != 2 + 3 * operations) return -1;
    for (0..operations) |i| {
        const op = input[2 + 3 * i];
        const key = input[3 + 3 * i];
        const value = input[4 + 3 * i];
        if (op < 0 or op > 6) return -1;
        if (op <= 2) {
            if (key < -2147483648 or key > 2147483647) return -1;
            if (op == 0) {
                if (value < -2147483648 or value > 2147483647) return -1;
            } else if (value != 0) return -1;
        } else if (key != 0 or value != 0) return -1;
    }
    const required = operations * 16;
    if (output == null or output_capacity < required) return -2;
    const out = @as([*]u8, @ptrCast(output));
    var keys = [_]i64{0} ** 16;
    var values = [_]i64{0} ** 16;
    var count: usize = 0;
    var hits: i64 = 0;
    var misses: i64 = 0;
    for (0..operations) |i| {
        const op = input[2 + 3 * i];
        const key = input[3 + 3 * i];
        const value = input[4 + 3 * i];
        var first: i64 = 0;
        var second: i64 = 0;
        if (op == 0) {
            var found = count;
            for (0..count) |j| { if (keys[j] == key) { found = j; break; } }
            if (found < count) {
                var j = found;
                while (j + 1 < count) : (j += 1) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; }
                count -= 1;
            }
            if (count == capacity) count -= 1;
            keys[count] = key; values[count] = value; count += 1; first = 1;
        } else if (op == 1) {
            var found = count;
            for (0..count) |j| { if (keys[j] == key) { found = j; break; } }
            if (found < count) { hits += 1; first = 1; second = values[found]; } else { misses += 1; }
        } else if (op == 2) {
            var found = count;
            for (0..count) |j| { if (keys[j] == key) { found = j; break; } }
            if (found < count) {
                first = 1; second = values[found];
                var j = found;
                while (j + 1 < count) : (j += 1) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; }
                count -= 1;
            }
        } else if (op == 3) first = @intCast(count)
        else if (op == 4) first = hits
        else if (op == 5) first = misses
        else { count = 0; hits = 0; misses = 0; first = 1; }
        put_i64_le(out, 16 * i, first);
        put_i64_le(out, 16 * i + 8, second);
    }
    return @intCast(2 * operations);
}
