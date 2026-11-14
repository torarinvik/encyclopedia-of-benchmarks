export fn longest_common_substring_sam(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > 515) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > 256) return -1;
    const n: usize = @intCast(input[0]);
    if (length < n+2 or input[n+1] < 0 or input[n+1] > 256) return -1;
    const m: usize = @intCast(input[n+1]);
    if (length != n+m+2) return -1;
    for (0..n) |i| if (input[1+i] < 32 or input[1+i] > 126) { return -1; };
    for (0..m) |i| if (input[n+2+i] < 32 or input[n+2+i] > 126) { return -1; };
    var edges = [_]i32{-1} ** 48735; var links = [_]i32{-1} ** 513; var lens = [_]usize{0} ** 513;
    var size: usize = 1; var last: usize = 0;
    for (0..n) |i| {
        const symbol: usize = @intCast(input[1+i]-32); const current = size; size += 1;
        lens[current] = lens[last]+1; var p: i32 = @intCast(last);
        while (p >= 0 and edges[95*@as(usize, @intCast(p))+symbol] < 0) {
            const index: usize = @intCast(p); edges[95*index+symbol] = @intCast(current); p = links[index];
        }
        if (p < 0) { links[current] = 0; } else {
            const pi: usize = @intCast(p); const q: usize = @intCast(edges[95*pi+symbol]);
            if (lens[pi]+1 == lens[q]) { links[current] = @intCast(q); } else {
                const clone = size; size += 1;
                for (0..95) |a| edges[95*clone+a] = edges[95*q+a];
                links[clone] = links[q]; lens[clone] = lens[pi]+1;
                while (p >= 0 and edges[95*@as(usize, @intCast(p))+symbol] == @as(i32, @intCast(q))) {
                    const index: usize = @intCast(p); edges[95*index+symbol] = @intCast(clone); p = links[index];
                }
                links[q] = @intCast(clone); links[current] = @intCast(clone);
            }
        }
        last = current;
    }
    var state: usize = 0; var matched: usize = 0; var best: usize = 0;
    for (0..m) |i| {
        const symbol: usize = @intCast(input[n+2+i]-32);
        while (state != 0 and edges[95*state+symbol] < 0) { state = @intCast(links[state]); matched = lens[state]; }
        const next = edges[95*state+symbol];
        if (next < 0) { state = 0; matched = 0; } else { state = @intCast(next); matched += 1; best = @max(best, matched); }
    }
    return @intCast(best);
}
