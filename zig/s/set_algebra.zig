const MAX_SET_SIZE: usize = 64;
const MAX_RESULT_SIZE: usize = 2 * MAX_SET_SIZE;
const MAX_INPUT_LENGTH: usize = 4 + 2 * MAX_SET_SIZE;

fn contains(values: []const i64, target: i64) bool {
    for (values) |value| { if (value == target) return true; }
    return false;
}
fn isSubset(left: []const i64, right: []const i64) bool {
    if (left.len > right.len) return false;
    for (left) |value| { if (!contains(right, value)) return false; }
    return true;
}
fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn set_algebra(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const operation = input[0];
    const left_raw = input[1];
    const right_raw = input[2];
    const query_key = input[3];
    if (operation < 0 or operation > 8 or left_raw < 0 or left_raw > MAX_SET_SIZE or right_raw < 0 or right_raw > MAX_SET_SIZE or query_key < -1_000_000 or query_key > 1_000_000) return -1;
    const left_length: usize = @intCast(left_raw);
    const right_length: usize = @intCast(right_raw);
    if (length != 4 + left_length + right_length) return -1;

    var left: [MAX_SET_SIZE]i64 = @splat(0);
    var right: [MAX_SET_SIZE]i64 = @splat(0);
    var result: [MAX_RESULT_SIZE]i64 = @splat(0);
    var left_count: usize = 0;
    var right_count: usize = 0;
    var result_count: usize = 0;
    for (0..left_length) |i| {
        const value = input[4 + i];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        if (!contains(left[0..left_count], value)) { left[left_count] = value; left_count += 1; }
    }
    for (0..right_length) |i| {
        const value = input[4 + left_length + i];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        if (!contains(right[0..right_count], value)) { right[right_count] = value; right_count += 1; }
    }
    const a = left[0..left_count];
    const b = right[0..right_count];

    if (operation == 0) { result[0] = @intFromBool(contains(a, query_key)); result_count = 1; }
    else if (operation == 1) { result[0] = @intFromBool(isSubset(a, b)); result_count = 1; }
    else if (operation == 2) { result[0] = @intFromBool(a.len < b.len and isSubset(a, b)); result_count = 1; }
    else if (operation == 3) { result[0] = @intFromBool(isSubset(b, a)); result_count = 1; }
    else if (operation == 4) { result[0] = @intFromBool(b.len < a.len and isSubset(b, a)); result_count = 1; }
    else if (operation == 5) {
        for (a) |value| { result[result_count] = value; result_count += 1; }
        for (b) |value| { if (!contains(a, value)) { result[result_count] = value; result_count += 1; } }
    } else if (operation == 6) {
        for (a) |value| { if (contains(b, value)) { result[result_count] = value; result_count += 1; } }
    } else if (operation == 7) {
        for (a) |value| { if (!contains(b, value)) { result[result_count] = value; result_count += 1; } }
    } else {
        for (a) |value| { if (!contains(b, value)) { result[result_count] = value; result_count += 1; } }
        for (b) |value| { if (!contains(a, value)) { result[result_count] = value; result_count += 1; } }
    }
    var i: usize = 1;
    while (i < result_count) : (i += 1) {
        const value = result[i];
        var j = i;
        while (j > 0 and result[j - 1] > value) : (j -= 1) result[j] = result[j - 1];
        result[j] = value;
    }

    const output_bytes = result_count * 8;
    if (capacity < output_bytes or (output_bytes > 0 and output == null)) return -2;
    for (0..result_count) |i| putI64Le(output, i * 8, result[i]);
    return @intCast(output_bytes);
}
