fn storeI64Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn proportional_fair_scheduling(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 131) return -1;
    if (values[0] < 0 or values[0] > 64 or values[1] < 1 or values[1] > 1_000_000) return -1;
    const process_count: usize = @intCast(values[0]);
    const total_resources = values[1];
    if (length != 2 + 2 * process_count) return -1;

    var name_ids: [64]i64 = @splat(0);
    var weights: [64]i64 = @splat(0);
    var total_weight: i64 = 0;
    for (0..process_count) |process| {
        const name_id = values[2 + 2 * process];
        const weight = values[3 + 2 * process];
        if (name_id < -2147483648 or name_id > 2147483647 or weight < 1 or weight > 1_000_000) return -1;
        name_ids[process] = name_id;
        weights[process] = weight;
        total_weight += weight;
    }

    if (process_count == 0) return 0;
    const required = process_count * 16;
    if (output == null or output_capacity < required) return -2;
    for (0..process_count) |process| {
        const quotient = @as(f64, @floatFromInt(weights[process])) / @as(f64, @floatFromInt(total_weight));
        const share = quotient * @as(f64, @floatFromInt(total_resources));
        const allocation: i32 = @intFromFloat(share);
        storeI64Le(output, process * 16, name_ids[process]);
        storeI64Le(output, process * 16 + 8, @intCast(allocation));
    }
    return @intCast(required);
}
