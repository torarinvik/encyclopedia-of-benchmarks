/// Unwind the logarithmic small-k Josephus recurrence using a bounded frame stack.
pub export fn josephus_batched_small_k(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const n0 = values[0];
    const k = values[1];
    if (n0 < 1 or n0 > 1_000_000 or k < 1 or k > 32) return -1;
    if (n0 == 1) return 0;
    if (k == 1) return n0 - 1;
    var frames: [1024]i64 = @splat(0);
    var depth: usize = 0;
    var n = n0;
    while (n > 1) {
        if (depth == frames.len) return -1;
        frames[depth] = n;
        depth += 1;
        n = if (n < k) n - 1 else n - @divTrunc(n, k);
    }
    var survivor: i64 = 0;
    while (depth > 0) {
        depth -= 1;
        const m = frames[depth];
        if (m < k) survivor = @mod(survivor + k, m) else {
            survivor -= @mod(m, k);
            if (survivor < 0) survivor += m else survivor += @divTrunc(survivor, k - 1);
        }
    }
    return survivor;
}
