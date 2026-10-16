export fn car_pool(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 2 or length > 194) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > 1000 or values[1] < 0 or values[1] > 64) return -1;
    const capacity: i32 = @intCast(values[0]);
    const trip_count: usize = @intCast(values[1]);
    if (length != 2 + 3 * trip_count) return -1;

    var events: [1001]i32 = @splat(0);
    for (0..trip_count) |trip| {
        const offset = 2 + 3 * trip;
        const passengers = values[offset];
        const origin = values[offset + 1];
        const destination = values[offset + 2];
        if (passengers < 1 or passengers > 1000 or origin < 0 or origin >= destination or destination > 1000) return -1;
        events[@intCast(origin)] += @intCast(passengers);
        events[@intCast(destination)] -= @intCast(passengers);
    }

    var occupants: i32 = 0;
    for (0..1000) |position| {
        occupants += events[position];
        if (occupants > capacity) return 0;
    }
    return 1;
}
