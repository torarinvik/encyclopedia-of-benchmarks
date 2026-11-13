fn root(parent: *[36]usize, start: usize) usize {
    var x = start;
    while (parent[x] != x) { parent[x] = parent[parent[x]]; x = parent[x]; }
    return x;
}

export fn statistical_region_merging_table(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > 74) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 6) return -1;
    const width: usize = @intCast(input[1]);
    const n = @as(usize, @intCast(input[0])) * width;
    if (length != 2+2*n) return -1;
    for (0..n) |i| if (input[2+i] < 0 or input[2+i] > 65535 or input[2+n+i] < 0 or input[2+n+i] > 255) { return -1; };
    var parent: [36]usize = undefined;
    var sizes: [36]usize = undefined;
    var minimum: [36]usize = undefined;
    var sums: [36]i64 = undefined;
    for (0..n) |i| { parent[i] = i; sizes[i] = 1; minimum[i] = i; sums[i] = input[2+n+i]; }
    for (0..256) |diff| for (0..n) |p| {
        var neighbors: [2]usize = undefined;
        var count: usize = 0;
        if (p % width + 1 < width) { neighbors[count] = p+1; count += 1; }
        if (p+width < n) { neighbors[count] = p+width; count += 1; }
        for (neighbors[0..count]) |q| {
            var d = input[2+n+p] - input[2+n+q];
            if (d < 0) d = -d;
            if (d != @as(i64, @intCast(diff))) continue;
            var a = root(&parent, p);
            var b = root(&parent, q);
            if (a == b) continue;
            const na: i64 = @intCast(sizes[a]);
            const nb: i64 = @intCast(sizes[b]);
            const delta = sums[a]*nb - sums[b]*na;
            const bound = input[1+sizes[a]] + input[1+sizes[b]];
            if (delta*delta > bound*na*na*nb*nb) continue;
            if (sizes[a] < sizes[b]) { const t = a; a = b; b = t; }
            parent[b] = a; sizes[a] += sizes[b]; sums[a] += sums[b];
            minimum[a] = @min(minimum[a], minimum[b]);
        }
    };
    if (output_opt == null or capacity < n) return -2;
    const output = output_opt.?;
    for (0..n) |i| output[i] = @intCast(minimum[root(&parent, i)]);
    return @intCast(n);
}
