fn assign(job: usize, starts: *const [32]usize, ends: *const [32]usize, slots: *[32]i32, seen: *[32]bool) bool {
    var slot = starts[job];
    while (slot <= ends[job]) : (slot += 1) {
        if (seen[slot]) continue;
        seen[slot] = true;
        const old = slots[slot];
        if (old < 0 or assign(@intCast(old), starts, ends, slots, seen)) {
            slots[slot] = @intCast(job);
            return true;
        }
    }
    return false;
}

export fn unit_job_release_deadline_weighted_matching(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 1 or length > 98 or input[0] < 0 or input[0] > 32) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 3*n) return -1;
    var starts = [_]usize{0} ** 32; var ends = [_]usize{0} ** 32;
    var weights = [_]i64{0} ** 32; var order = [_]usize{0} ** 32;
    var slots = [_]i32{-1} ** 32;
    for (0..n) |i| {
        const r = input[1+3*i]; const d = input[2+3*i]; const w = input[3+3*i];
        if (r < 0 or d < r or d >= 32 or w < 0 or w > 1000000) return -1;
        starts[i] = @intCast(r); ends[i] = @intCast(d); weights[i] = w;
        var j = i;
        while (j > 0 and weights[order[j-1]] < w) : (j -= 1) order[j] = order[j-1];
        order[j] = i;
    }
    var total: i64 = 0;
    for (0..n) |i| {
        var seen = [_]bool{false} ** 32;
        const job = order[i];
        if (assign(job, &starts, &ends, &slots, &seen)) total += weights[job];
    }
    return total;
}
