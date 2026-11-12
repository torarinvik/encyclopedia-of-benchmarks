const MAX_Q: usize = 32;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_Q;

fn writeI64(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn circle_line_intersection_count(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 101) return -1;
    const center_x = input[0];
    const center_y = input[1];
    const radius = input[2];
    const query_value = input[3];
    if (center_x < -1000 or center_x > 1000 or center_y < -1000 or center_y > 1000 or
        radius < 0 or radius > 1000 or query_value < 0 or query_value > @as(i64, @intCast(MAX_Q))) return -1;
    const query_count: usize = @intCast(query_value);
    if (length != 4 + 3 * query_count) return -1;

    var a_values: [MAX_Q]i64 = @splat(0);
    var b_values: [MAX_Q]i64 = @splat(0);
    var c_values: [MAX_Q]i64 = @splat(0);
    for (0..query_count) |query| {
        const a = input[4 + 3 * query];
        const b = input[5 + 3 * query];
        const c = input[6 + 3 * query];
        if (a < -100 or a > 100 or b < -100 or b > 100 or (a == 0 and b == 0) or
            c < -200000 or c > 200000) return -1;
        a_values[query] = a;
        b_values[query] = b;
        c_values[query] = c;
    }
    const needed = 8 * query_count;
    if (needed > 0 and (output == null or capacity < needed)) return -2;

    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    for (0..query_count) |query| {
        const a = a_values[query];
        const b = b_values[query];
        const offset = a * center_x + b * center_y + c_values[query];
        const normal_squared = a * a + b * b;
        const discriminant = radius * radius * normal_squared - offset * offset;
        const count: i64 = if (discriminant > 0) 2 else if (discriminant == 0) 1 else 0;
        writeI64(&staged, 8 * query, count);
    }
    for (0..needed) |byte| output[byte] = staged[byte];
    return @intCast(needed);
}
