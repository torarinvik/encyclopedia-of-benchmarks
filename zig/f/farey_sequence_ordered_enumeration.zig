fn fareyCount(order: i64) i64 {
    var a: i64 = 0;
    var b: i64 = 1;
    var c: i64 = 1;
    var d = order;
    var count: i64 = 1;
    while (true) {
        count += 1;
        if (c == d) break;
        const k = @divTrunc(order + b, d);
        const next_c = k * c - a;
        const next_d = k * d - b;
        a = c;
        b = d;
        c = next_c;
        d = next_d;
    }
    return count;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @intCast((bits >> @intCast(8 * byte)) & 0xff);
}

export fn farey_sequence_ordered_enumeration(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length != 1) return -1;
    const order = values.?[0];
    if (order < 1 or order > 32) return -1;
    const count = fareyCount(order);
    const required: usize = @intCast((1 + 2 * count) * 8);
    if (output == null or output_capacity < required) return -2;

    const result = output.?[0..required];
    storeI64Le(result.ptr, 0, count);
    storeI64Le(result.ptr, 8, 0);
    storeI64Le(result.ptr, 16, 1);
    var a: i64 = 0;
    var b: i64 = 1;
    var c: i64 = 1;
    var d = order;
    var position: usize = 24;
    while (true) {
        storeI64Le(result.ptr, position, c);
        storeI64Le(result.ptr, position + 8, d);
        position += 16;
        if (c == d) break;
        const k = @divTrunc(order + b, d);
        const next_c = k * c - a;
        const next_d = k * d - b;
        a = c;
        b = d;
        c = next_c;
        d = next_d;
    }
    return @intCast(required);
}
