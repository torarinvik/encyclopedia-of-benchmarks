export fn unrolled_linked_list_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024) return -1;
    var chunks: [512][5]i64 = undefined;
    var counts: [512]usize = @splat(0);
    var next: [512]usize = @splat(512);
    var blocks: usize = 0;
    for (0..length) |i| {
        const value = values[i];
        if (value < -1000000 or value > 1000000) return -1;
        if (blocks == 0) { blocks = 1; counts[0] = 1; chunks[0][0] = value; }
        else if (counts[blocks - 1] < 4) { chunks[blocks - 1][counts[blocks - 1]] = value; counts[blocks - 1] += 1; }
        else {
            const tail = blocks - 1;
            const keep = counts[tail] / 2 + 1;
            const moved = counts[tail] - keep;
            for (0..moved) |j| chunks[blocks][j] = chunks[tail][keep + j];
            counts[tail] = keep; chunks[blocks][moved] = value; counts[blocks] = moved + 1; next[tail] = blocks; blocks += 1;
        }
    }
    var checksum: i64 = 0; var index: usize = 0;
    var b: usize = 0; while (b < 512) { for (0..counts[b]) |j| { checksum += @as(i64, @intCast(index + 1)) * (chunks[b][j] + 1000000); index += 1; } if (next[b] == 512) break; b = next[b]; }
    return checksum;
}
