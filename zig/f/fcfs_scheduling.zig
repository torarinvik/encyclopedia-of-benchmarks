fn storeI64Le(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[position + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn fcfs_scheduling(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 193) return -2;
    if (values[0] < 0 or values[0] > 64) return -2;
    const count: usize = @intCast(values[0]);
    if (length != 1 + 3 * count) return -2;

    var ids: [64]i64 = @splat(0);
    var arrivals: [64]i64 = @splat(0);
    var bursts: [64]i64 = @splat(0);
    var order: [64]usize = @splat(0);
    for (0..count) |i| {
        const id = values[1 + 3 * i];
        const arrival = values[2 + 3 * i];
        const burst = values[3 + 3 * i];
        if (id < 0 or id > 63 or arrival < 0 or arrival > 1_000_000
            or burst < 1 or burst > 1_000_000) return -2;
        for (0..i) |previous| {
            if (ids[previous] == id) return -2;
        }
        ids[i] = id;
        arrivals[i] = arrival;
        bursts[i] = burst;
        order[i] = i;
    }
    if (count > 1) {
        for (1..count) |i| {
            const key = order[i];
            var j = i;
            while (j > 0 and (arrivals[order[j - 1]] > arrivals[key]
                or (arrivals[order[j - 1]] == arrivals[key] and ids[order[j - 1]] > ids[key]))) {
                order[j] = order[j - 1];
                j -= 1;
            }
            order[j] = key;
        }
    }

    const required = count * 48;
    if (output_capacity < required) return -2;
    var elapsed: i64 = 0;
    for (0..count) |position| {
        const i = order[position];
        if (elapsed < arrivals[i]) elapsed = arrivals[i];
        const completion = elapsed + bursts[i];
        const turnaround = completion - arrivals[i];
        const waiting = turnaround - bursts[i];
        const fields = [6]i64{ ids[i], arrivals[i], bursts[i], completion, turnaround, waiting };
        for (0..6) |field| {
            storeI64Le(output, position * 48 + field * 8, fields[field]);
        }
        elapsed = completion;
    }
    return @intCast(count);
}
