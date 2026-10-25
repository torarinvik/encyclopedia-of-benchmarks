const MAX_EVENTS: usize = 64;
const MAX_EPOCH: i64 = 15;
const MAX_ADDRESS: i64 = 255;

export fn analyzer(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > 194) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > MAX_EVENTS) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + 3 * count) return -1;
    var latest_writer = [_]i64{-1} ** 256;
    var conflicts: i64 = 0;
    var previous_epoch: i64 = 0;
    for (0..count) |event| {
        const base = 1 + 3 * event;
        const epoch = input[base];
        const opcode = input[base + 1];
        const address_value = input[base + 2];
        if (epoch < previous_epoch or epoch < 0 or epoch > MAX_EPOCH
            or (opcode != 0 and opcode != 1) or address_value < 0 or address_value > MAX_ADDRESS) return -1;
        previous_epoch = epoch;
        const address: usize = @intCast(address_value);
        if (opcode == 0) {
            latest_writer[address] = @intCast(event);
        } else {
            for (0..event) |prior| {
                const prior_base = 1 + 3 * prior;
                if (input[prior_base] < epoch and input[prior_base + 1] == 0
                    and input[prior_base + 2] == address_value
                    and latest_writer[address] == @as(i64, @intCast(prior))) conflicts += 1;
            }
        }
    }
    return conflicts;
}
