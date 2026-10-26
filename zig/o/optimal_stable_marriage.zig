const MAX_N: usize = 8;
const MAX_INPUT_LENGTH: usize = 129;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn optimal_stable_marriage(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?;
    const n_value = values[0];
    if (n_value < 0 or n_value > 8) return -1;
    const n: usize = @intCast(n_value);
    const side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    var men_preferences: [64]usize = [_]usize{0} ** 64;
    var women_rank: [64]usize = [_]usize{0} ** 64;
    for (0..2 * n) |row| {
        var seen: [MAX_N]bool = [_]bool{false} ** MAX_N;
        const start = if (row < n) 1 + row * n else 1 + side_size + (row - n) * n;
        for (0..n) |rank| {
            const value = values[start + rank];
            if (value < 0 or value >= n_value) return -1;
            const participant: usize = @intCast(value);
            if (seen[participant]) return -1;
            seen[participant] = true;
            if (row < n) men_preferences[row * n + rank] = participant
            else women_rank[(row - n) * n + participant] = rank;
        }
    }
    const output_bytes = 16 * n;
    if (output == null or capacity < output_bytes) return -2;
    const out = output.?;

    var final_partner: [MAX_N]i64 = [_]i64{-1} ** MAX_N;
    for (0..n) |threshold| {
        var woman_partner: [MAX_N]i64 = [_]i64{-1} ** MAX_N;
        var man_partner: [MAX_N]i64 = [_]i64{-1} ** MAX_N;
        var next_rank: [MAX_N]usize = [_]usize{0} ** MAX_N;
        var queue: [MAX_N]usize = [_]usize{0} ** MAX_N;
        for (0..n) |i| queue[i] = i;
        var head: usize = 0;
        var tail: usize = 0;
        var queued: usize = n;
        while (queued > 0) {
            const man = queue[head];
            head = (head + 1) % n;
            queued -= 1;
            while (next_rank[man] < n) {
                const rank = next_rank[man];
                next_rank[man] += 1;
                const woman = men_preferences[man * n + rank];
                if (rank > threshold or women_rank[woman * n + man] > threshold) continue;
                const incumbent = woman_partner[woman];
                if (incumbent < 0 or women_rank[woman * n + man] < women_rank[woman * n + @as(usize, @intCast(incumbent))]) {
                    woman_partner[woman] = @intCast(man);
                    man_partner[man] = @intCast(woman);
                    if (incumbent >= 0) {
                        man_partner[@intCast(incumbent)] = -1;
                        queue[tail] = @intCast(incumbent);
                        tail = (tail + 1) % n;
                        queued += 1;
                    }
                    break;
                }
                queue[tail] = man;
                tail = (tail + 1) % n;
                queued += 1;
                break;
            }
        }
        var matched: usize = 0;
        for (0..n) |man| if (man_partner[man] >= 0) { matched += 1; };
        if (matched == n) {
            for (0..n) |man| final_partner[man] = man_partner[man];
            break;
        }
    }
    for (0..n) |man| {
        storeI64Le(out, (man * 2) * 8, @intCast(man));
        storeI64Le(out, (man * 2 + 1) * 8, final_partner[man]);
    }
    return @intCast(output_bytes);
}
