export fn shortest_absent_substring_sam(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 2 or input[0] > 4 or input[1] < 0 or input[1] > 64) return -1;
    const alphabet: usize = @intCast(input[0]); const n: usize = @intCast(input[1]);
    if (length != 2+n) return -1;
    for (0..n) |i| if (input[2+i] < 0 or input[2+i] >= @as(i64, @intCast(alphabet))) { return -1; };
    var edges = [_]i32{-1} ** 516; var links = [_]i32{-1} ** 129; var lens = [_]usize{0} ** 129;
    var size: usize = 1; var last: usize = 0;
    for (0..n) |i| {
        const symbol: usize = @intCast(input[2+i]); const current = size; size += 1;
        lens[current] = lens[last]+1; var p: i32 = @intCast(last);
        while (p >= 0 and edges[4*@as(usize, @intCast(p))+symbol] < 0) {
            const index: usize = @intCast(p); edges[4*index+symbol] = @intCast(current); p = links[index];
        }
        if (p < 0) { links[current] = 0; } else {
            const pi: usize = @intCast(p); const q: usize = @intCast(edges[4*pi+symbol]);
            if (lens[pi]+1 == lens[q]) { links[current] = @intCast(q); } else {
                const clone = size; size += 1;
                for (0..4) |a| edges[4*clone+a] = edges[4*q+a];
                links[clone] = links[q]; lens[clone] = lens[pi]+1;
                while (p >= 0 and edges[4*@as(usize, @intCast(p))+symbol] == @as(i32, @intCast(q))) {
                    const index: usize = @intCast(p); edges[4*index+symbol] = @intCast(clone); p = links[index];
                }
                links[q] = @intCast(clone); links[current] = @intCast(clone);
            }
        }
        last = current;
    }
    var counts = [_]usize{0} ** 65; var order = [_]usize{0} ** 129; var dp = [_]usize{0} ** 129;
    for (0..size) |s| counts[lens[s]] += 1;
    for (1..n+1) |i| counts[i] += counts[i-1];
    for (0..size) |offset| { const s = size-1-offset; counts[lens[s]] -= 1; order[counts[lens[s]]] = s; }
    for (0..size) |offset| {
        const s = order[size-1-offset]; var best: usize = 100;
        for (0..alphabet) |a| {
            const child = edges[4*s+a]; var candidate: usize = 1;
            if (child >= 0) candidate += dp[@intCast(child)];
            best = @min(best, candidate);
        }
        dp[s] = best;
    }
    var result: [6]u8 = undefined; var count: usize = 0; var state: i32 = 0;
    while (state >= 0) {
        const s: usize = @intCast(state);
        for (0..alphabet) |a| {
            const child = edges[4*s+a]; var eligible = child < 0 and dp[s] == 1;
            if (child >= 0) eligible = dp[s] == 1+dp[@as(usize, @intCast(child))];
            if (eligible) { result[count] = @intCast(a); count += 1; state = child; break; }
        }
    }
    if (output_opt == null or capacity < count) return -2;
    const output = output_opt.?;
    for (0..count) |i| output[i] = result[i];
    return @intCast(count);
}
