fn add(tree: *[65]i64, n: usize, position: usize, delta: i64) void {
    var i = position + 1;
    while (i <= n) : (i += i & (~i +% 1)) tree[i] += delta;
}

fn prefix(tree: *const [65]i64, end: usize) i64 {
    var i = end;
    var sum: i64 = 0;
    while (i > 0) : (i &= i-1) sum += tree[i];
    return sum;
}

export fn offline_range_distinct_fenwick(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > 195) return -1;
    const input = input_opt.?;
    const nr = input[0];
    const qr = input[1];
    if (nr < 1 or nr > 64 or qr < 0 or qr > 64) return -1;
    const n: usize = @intCast(nr);
    const q: usize = @intCast(qr);
    if (length != 2+n+2*q) return -1;
    for (0..n) |i| if (input[2+i] < 0 or input[2+i] > 255) return -1;
    var head = [_]i64{-1} ** 65;
    var next = [_]i64{-1} ** 64;
    var last = [_]i64{-1} ** 256;
    var tree = [_]i64{0} ** 65;
    for (0..q) |i| {
        const left = input[2+n+2*i];
        const right = input[3+n+2*i];
        if (left < 0 or left > right or right > nr) return -1;
        const r: usize = @intCast(right);
        next[i] = head[r]; head[r] = @intCast(i);
    }
    var result: i64 = 0;
    for (0..n+1) |right| {
        if (right > 0) {
            const value: usize = @intCast(input[1+right]);
            if (last[value] >= 0) add(&tree, n, @intCast(last[value]), -1);
            add(&tree, n, right-1, 1); last[value] = @intCast(right-1);
        }
        var query = head[right];
        while (query >= 0) {
            const index: usize = @intCast(query);
            const left: usize = @intCast(input[2+n+2*index]);
            result += (query+1) * (prefix(&tree,right)-prefix(&tree,left));
            query = next[index];
        }
    }
    return result;
}
