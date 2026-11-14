export fn space_saving_frequent_items(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 67) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 64) return -1;
    const k: usize = @intCast(input[0]);
    const n: usize = @intCast(input[1]);
    if (length != 2+n) return -1;
    for (0..n) |i| if (input[2+i] < -1000 or input[2+i] > 1000) { return -1; };
    var items: [8]i64 = @splat(0);
    var estimates: [8]i64 = @splat(0);
    var errors: [8]i64 = @splat(0);
    var used: usize = 0;
    for (0..n) |i| {
        const item = input[2+i];
        var found: ?usize = null;
        for (0..used) |j| {
            if (items[j] == item) { found = j; break; }
        }
        if (found) |j| {
            estimates[j] += 1;
        } else if (used < k) {
            items[used] = item; estimates[used] = 1; errors[used] = 0; used += 1;
        } else {
            var victim: usize = 0;
            for (1..used) |j| {
                if (estimates[j] < estimates[victim] or
                    (estimates[j] == estimates[victim] and items[j] < items[victim])) victim = j;
            }
            const minimum = estimates[victim];
            items[victim] = item; estimates[victim] = minimum + 1; errors[victim] = minimum;
        }
    }
    var sort_index: usize = 1;
    while (sort_index < used) : (sort_index += 1) {
        var j = sort_index;
        while (j > 0 and items[j] < items[j-1]) : (j -= 1) {
            const item = items[j]; items[j] = items[j-1]; items[j-1] = item;
            const estimate = estimates[j]; estimates[j] = estimates[j-1]; estimates[j-1] = estimate;
            const err = errors[j]; errors[j] = errors[j-1]; errors[j-1] = err;
        }
    }
    const bytes = 8 * (1 + 3 * used);
    if (output_opt == null or capacity < bytes) return -2;
    var fields: [25]i64 = @splat(0);
    fields[0] = @intCast(used);
    for (0..used) |i| {
        fields[1+3*i] = items[i]; fields[2+3*i] = estimates[i]; fields[3+3*i] = errors[i];
    }
    var staged: [200]u8 = @splat(0);
    for (0..1+3*used) |i| {
        const bits: u64 = @bitCast(fields[i]);
        for (0..8) |b| staged[8*i+b] = @truncate(bits >> @intCast(8*b));
    }
    const output = output_opt.?;
    for (0..bytes) |i| output[i] = staged[i];
    return @intCast(bytes);
}
