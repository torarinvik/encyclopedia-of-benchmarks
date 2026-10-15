fn storeI64Le(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn fair_share_scheduling(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 3 or length > 323) return -2;
    if (values[0] < 0 or values[0] > 64 or values[1] < 0 or values[1] > 128
        or values[2] < 0 or values[2] > 1_000_000) return -2;
    const user_count: usize = @intCast(values[0]);
    const task_count: usize = @intCast(values[1]);
    const resources = values[2];
    if (length != 3 + user_count + 2 * task_count) return -2;

    var ids: [64]i64 = @splat(0);
    var weights: [64]i64 = @splat(0);
    var order: [64]usize = @splat(0);
    for (0..user_count) |user| {
        const id = values[3 + user];
        if (id < 0 or id > 63) return -2;
        for (0..user) |previous| if (ids[previous] == id) return -2;
        ids[user] = id;
        order[user] = user;
    }
    const task_start = 3 + user_count;
    for (0..task_count) |task| {
        const owner = values[task_start + 2 * task];
        const weight = values[task_start + 2 * task + 1];
        if (owner < 0 or owner > 63 or weight < 0 or weight > 1_000_000) return -2;
        for (0..user_count) |user| {
            if (ids[user] == owner) {
                weights[user] += weight;
                break;
            }
        }
    }
    if (user_count > 1) {
        for (1..user_count) |i| {
            const key = order[i];
            var j = i;
            while (j > 0 and ids[order[j - 1]] > ids[key]) {
                order[j] = order[j - 1];
                j -= 1;
            }
            order[j] = key;
        }
    }
    var total_weight: i64 = 0;
    for (0..user_count) |user| total_weight += weights[user];
    const required = user_count * 24;
    if (output_capacity < required) return -2;
    for (0..user_count) |position| {
        const user = order[position];
        const allocation = if (total_weight == 0) 0 else @divFloor(weights[user] * resources, total_weight);
        storeI64Le(output, position * 24, ids[user]);
        storeI64Le(output, position * 24 + 8, weights[user]);
        storeI64Le(output, position * 24 + 16, allocation);
    }
    return @intCast(user_count);
}
