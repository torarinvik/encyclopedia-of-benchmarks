export fn kth_factor(n_value: i64, k_value: i64) i64 {
    if (n_value < 1 or n_value > 10000 or k_value < 1 or k_value > n_value) return -1;
    const n: i32 = @intCast(n_value);
    const k: i32 = @intCast(k_value);
    var factors_found: i32 = 0;
    var i: i32 = 1;
    while (i <= n) : (i += 1) {
        if (@mod(n, i) == 0) {
            factors_found += 1;
            if (factors_found == k) return i;
        }
    }
    return -1;
}
