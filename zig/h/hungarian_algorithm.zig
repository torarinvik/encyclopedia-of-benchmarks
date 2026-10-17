fn storeI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |b| output[offset + b] = @truncate(bits >> @as(u5, @intCast(8 * b)));
}
export fn hungarian_algorithm(input: [*c]const i32, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 67) return -1;
    const rows = input[0]; const cols = input[1];
    if (rows < 1 or rows > 8 or cols < 1 or cols > 8 or length != 2 + @as(usize, @intCast(rows * cols))) return -1;
    for (0..@as(usize, @intCast(rows * cols))) |k| { if (input[2 + k] < 0 or input[2 + k] > 1000) return -1; }
    const n: usize = @intCast(@max(rows, cols));
    var a = [_]i32{0} ** 81; var u = [_]i32{0} ** 9; var v = [_]i32{0} ** 9; var p = [_]i32{0} ** 9; var way = [_]i32{0} ** 9;
    for (0..@as(usize, @intCast(rows))) |i| {
        for (0..@as(usize, @intCast(cols))) |j| { a[i * 9 + j] = input[2 + i * @as(usize, @intCast(cols)) + j]; }
    }
    for (1..n + 1) |i| {
        p[0] = @intCast(i); var j0: usize = 0; var minv = [_]i32{2147483647} ** 9; var used = [_]bool{false} ** 9;
        while (true) {
            used[j0] = true; const i0: usize = @intCast(p[j0]); var delta: i32 = 2147483647; var j1: usize = 0;
            for (1..n + 1) |j| if (!used[j]) {
                const cur = a[(i0 - 1) * 9 + j - 1] - u[i0] - v[j];
                if (cur < minv[j]) { minv[j] = cur; way[j] = @intCast(j0); }
                if (minv[j] < delta) { delta = minv[j]; j1 = j; }
            };
            for (0..n + 1) |j| { if (used[j]) { u[@intCast(p[j])] += delta; v[j] -= delta; } else { minv[j] -= delta; } }
            j0 = j1; if (p[j0] == 0) break;
        }
        while (true) { const j1: usize = @intCast(way[j0]); p[j0] = p[j1]; j0 = j1; if (j0 == 0) break; }
    }
    var matched = [_]i32{-1} ** 9;
    for (1..n + 1) |j| if (p[j] != 0) { matched[@intCast(p[j] - 1)] = @intCast(j - 1); };
    var assignments = [_]i32{0} ** 8; var total: i32 = 0;
    for (0..@as(usize, @intCast(rows))) |i| { const j = matched[i]; assignments[i] = if (j >= 0 and j < cols) j else -1; if (assignments[i] >= 0) total += input[2 + i * @as(usize, @intCast(cols)) + @as(usize, @intCast(assignments[i]))]; }
    const bytes = 4 * (@as(usize, @intCast(rows)) + 1);
    if (output == null or capacity < bytes) return -2;
    for (0..@as(usize, @intCast(rows))) |i| storeI32Le(output, 4 * i, assignments[i]);
    storeI32Le(output, 4 * @as(usize, @intCast(rows)), total);
    return @intCast(bytes);
}
