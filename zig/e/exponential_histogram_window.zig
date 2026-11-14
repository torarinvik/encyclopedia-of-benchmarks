pub export fn exponential_histogram_window(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 130 or input[0] < 1 or input[0] > 64 or input[1] < 0 or input[1] > 128) return -1;
    const window: usize = @intCast(input[0]);
    const n: usize = @intCast(input[1]);
    if (length != 2+n) return -1;
    for (0..n) |i| { if (input[2+i] != 0 and input[2+i] != 1) return -1; }
    if (output == null or capacity < 8*n) return -2;
    var ends: [128]usize = @splat(0);
    var sizes: [128]usize = @splat(0);
    var used: usize = 0;
    for (0..n) |time| {
        while (used != 0 and time >= window and ends[0] <= time-window) {
            for (1..used) |j| { ends[j-1] = ends[j]; sizes[j-1] = sizes[j]; }
            used -= 1;
        }
        if (input[2+time] == 1) { ends[used] = time; sizes[used] = 1; used += 1; }
        var size: usize = 1;
        while (size <= 128) : (size *= 2) {
            var first = used;
            var second = used;
            var found: usize = 0;
            for (0..used) |j| {
                if (sizes[j] == size) {
                    if (found == 0) {
                        first = j;
                    } else if (found == 1) {
                        second = j;
                    }
                    found += 1;
                }
            }
            if (found > 2) {
                sizes[second] = 2*size;
                for (first+1..used) |j| { ends[j-1] = ends[j]; sizes[j-1] = sizes[j]; }
                used -= 1;
            }
        }
        var total: usize = 0;
        for (sizes[0..used]) |value| total += value;
        var bits: u64 = @intCast(2*total - (if (used != 0) sizes[0] else 0));
        for (0..8) |j| { output[8*time+j] = @truncate(bits); bits >>= 8; }
    }
    return @intCast(8*n);
}
