const MAX_BINS: usize = 256;
const MAX_SAMPLES: usize = 1024;

export fn parboil_histo(input: [*c]const i64, len: usize, output: [*c]u8, cap: usize) i64 {
    if (input == null or len < 3 or len > 3 + MAX_SAMPLES) return -1;
    const iterations = input[0];
    const bins = input[1];
    const samples = input[2];
    if (iterations < 0 or iterations > 8 or bins < 1 or bins > 256 or
        samples < 0 or samples > 1024 or len != 3 + @as(usize, @intCast(samples))) return -1;
    const bin_count: usize = @intCast(bins);
    const sample_count: usize = @intCast(samples);
    for (0..sample_count) |i| {
        if (input[3 + i] < 0 or input[3 + i] >= bins) return -1;
    }
    if (output == null or cap < bin_count) return -2;
    var histogram = [_]u8{0} ** MAX_BINS;
    var iter: i64 = 0;
    while (iter < iterations) : (iter += 1) {
        @memset(histogram[0..bin_count], 0);
        for (0..sample_count) |i| {
            const bin: usize = @intCast(input[3 + i]);
            if (histogram[bin] < 255) histogram[bin] += 1;
        }
    }
    for (0..bin_count) |i| output[i] = histogram[i];
    return bins;
}
