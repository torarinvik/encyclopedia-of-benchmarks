const MAX_N: usize = 128;
const MAX_K: usize = 512;
const MODULUS: i64 = 1_000_000_007;

export fn k_inverse_pairs_array(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > 3 or length != 2) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_N or input[1] < 0 or input[1] > MAX_K) return -1;
    const n: usize = @intCast(input[0]);
    const k: usize = @intCast(input[1]);
    const maximum_inversions = if (n == 0) 0 else n * (n - 1) / 2;
    if (k > maximum_inversions) return 0;

    var previous: [MAX_K + 1]i64 = @splat(0);
    var current: [MAX_K + 1]i64 = @splat(0);
    previous[0] = 1;
    for (0..n) |size_index| {
        const size = size_index + 1;
        var window: i64 = 0;
        for (0..k + 1) |inversions| {
            window += previous[inversions];
            if (inversions >= size) window -= previous[inversions - size];
            window = @rem(window, MODULUS);
            if (window < 0) window += MODULUS;
            current[inversions] = window;
        }
        previous = current;
        current = @splat(0);
    }
    return previous[k];
}
