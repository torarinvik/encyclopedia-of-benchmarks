export fn distance_between_bus_stops(input: [*]const i64, length: usize) i64 {
    if (length < 3 or length > 66) return -1;
    const stop_count = length - 2;
    const start_value = input[0];
    const destination_value = input[1];
    if (start_value < 0 or destination_value < 0
        or start_value >= @as(i64, @intCast(stop_count))
        or destination_value >= @as(i64, @intCast(stop_count))) return -1;

    const start: usize = @intCast(start_value);
    const destination: usize = @intCast(destination_value);
    const low = @min(start, destination);
    const high = @max(start, destination);
    var total: i64 = 0;
    var direct: i64 = 0;
    var index: usize = 0;
    while (index < stop_count) : (index += 1) {
        const distance = input[index + 2];
        if (distance < 0 or distance > 1000000) return -1;
        total += distance;
        if (index >= low and index < high) direct += distance;
    }
    const other = total - direct;
    return @min(direct, other);
}
