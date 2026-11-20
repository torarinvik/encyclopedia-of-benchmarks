const MAX_ITEMS: usize = 64;
const MAX_INPUT_WORDS: usize = 66;

export fn blelloch_parallel_prefix_scan(
    input_opt: ?[*]const i64,
    length: usize,
    output_opt: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_WORDS) return -1;
    const input = input_opt.?[0..length];
    const n64 = input[0];
    if (n64 < 1 or n64 > MAX_ITEMS) return -1;
    const n: usize = @intCast(n64);
    if (length != n + 1) return -1;

    var tree: [MAX_ITEMS]i64 = @splat(0);
    var padded: usize = 1;
    while (padded < n) : (padded <<= 1) {}
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < -1_000_000 or value > 1_000_000) return -1;
        tree[i] = value;
    }
    const output_bytes = n * 8;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const output = output_opt.?;

    var stride: usize = 2;
    while (stride <= padded) : (stride <<= 1) {
        const half = stride >> 1;
        var right = stride - 1;
        while (right < padded) : (right += stride) {
            tree[right] += tree[right - half];
        }
    }
    tree[padded - 1] = 0;
    stride = padded;
    while (stride >= 2) : (stride >>= 1) {
        const half = stride >> 1;
        var right = stride - 1;
        while (right < padded) : (right += stride) {
            const left = right - half;
            const partial = tree[left];
            tree[left] = tree[right];
            tree[right] += partial;
        }
    }
    for (0..n) |i| {
        const bits: u64 = @bitCast(tree[i]);
        for (0..8) |byte| output[i * 8 + byte] = @truncate(bits >> (byte * 8));
    }
    return @intCast(output_bytes);
}
