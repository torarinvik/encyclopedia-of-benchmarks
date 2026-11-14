fn between(ids: *const [16]i64, ring: i64, left: usize, item: usize, right: usize) bool {
    const distance = @mod(ids[item]-ids[left]+ring, ring);
    const span = @mod(ids[right]-ids[left]+ring, ring);
    return distance > 0 and (span == 0 or distance < span);
}
export fn chord_stabilization_trace(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 6 or length > 115) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 16 or input[2] < 0 or input[2] > 64) return -1;
    const ring = @as(i64, 1) << @as(u6, @intCast(input[0]));
    const n: usize = @intCast(input[1]); const q: usize = @intCast(input[2]);
    if (n > @as(usize, @intCast(ring)) or length != 3+3*n+q) return -1;
    var ids: [16]i64 = undefined; var succ: [16]usize = undefined; var pred: [16]i64 = undefined;
    for (0..n) |i| {
        if (input[3+i] < 0 or input[3+i] >= ring) return -1;
        if (i > 0 and input[3+i] <= ids[i-1]) return -1;
        if (input[3+n+i] < 0 or input[3+n+i] >= @as(i64, @intCast(n)) or input[3+2*n+i] < -1 or input[3+2*n+i] >= @as(i64, @intCast(n))) return -1;
        ids[i] = input[3+i]; succ[i] = @intCast(input[3+n+i]); pred[i] = input[3+2*n+i];
    }
    for (0..q) |i| if (input[3+3*n+i] < 0 or input[3+3*n+i] >= @as(i64, @intCast(n))) { return -1; };
    for (0..q) |i| {
        const node: usize = @intCast(input[3+3*n+i]); const candidate = pred[succ[node]];
        if (candidate >= 0 and between(&ids, ring, node, @intCast(candidate), succ[node])) succ[node] = @intCast(candidate);
        const receiver = succ[node];
        if (pred[receiver] < 0 or between(&ids, ring, @intCast(pred[receiver]), node, receiver)) pred[receiver] = @intCast(node);
    }
    if (output_opt == null or capacity < 2*n) return -2;
    const output = output_opt.?;
    for (0..n) |i| { output[i] = @intCast(succ[i]); output[n+i] = if (pred[i] < 0) 255 else @intCast(pred[i]); }
    return @intCast(2*n);
}
