const max_input: usize = 4;
const max_trips: usize = 32;

export fn ski_rental_deterministic(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const rent = input[0];
    const purchase = input[1];
    const trips = input[2];
    if (length != 3 or rent < 1 or rent > 32 or purchase < 1 or purchase > 64 or trips < 0 or trips > 32) return -1;
    const count: usize = @intCast(trips);
    if (output_opt == null or capacity < count) return -2;
    const output = output_opt.?;
    var actions: [max_trips]u8 = [_]u8{0} ** max_trips;
    const threshold = purchase / rent;
    for (0..count) |trip| {
        if (@as(i64, @intCast(trip)) < threshold) actions[trip] = 0
        else if (@as(i64, @intCast(trip)) == threshold) actions[trip] = 1
        else actions[trip] = 2;
    }
    @memcpy(output[0..count], actions[0..count]);
    return @intCast(count);
}
