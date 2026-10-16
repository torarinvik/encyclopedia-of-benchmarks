const INVALID_RESULT: f64 = -1.0e300;

export fn federated_averaging(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3 or length > 17) return INVALID_RESULT;
    const values = input.?;
    const clients_arg = values[0];
    if (clients_arg < 1 or clients_arg > 8) return INVALID_RESULT;
    const clients: usize = @intCast(clients_arg);
    if (length != 1 + 2 * clients) return INVALID_RESULT;
    var total: f64 = 0;
    for (0..clients) |i| {
        const weight = values[1 + i];
        if (weight < 0 or weight > 1000) return INVALID_RESULT;
        total += @floatFromInt(weight);
    }
    if (total <= 0) return INVALID_RESULT;
    var result: f64 = 0;
    for (0..clients) |i| {
        const value = values[1 + clients + i];
        if (value < -1000 or value > 1000) return INVALID_RESULT;
        const normalized = @as(f64, @floatFromInt(values[1 + i])) / total;
        result += normalized * @as(f64, @floatFromInt(value));
    }
    return result;
}
