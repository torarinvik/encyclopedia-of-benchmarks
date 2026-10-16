const MAX_VALUES: usize = 19;

fn det3(m: *const [9]i64) i64 {
    return m[0] * (m[4] * m[8] - m[5] * m[7]) -
        m[1] * (m[3] * m[8] - m[5] * m[6]) +
        m[2] * (m[3] * m[7] - m[4] * m[6]);
}

fn charpoly(m: *const [9]i64, n: usize) [3]i64 {
    var trace: i64 = 0;
    for (0..n) |i| trace += m[i * n + i];
    if (n == 1) return .{-trace, 0, 0};
    if (n == 2) return .{-trace, m[0] * m[3] - m[1] * m[2], 0};
    const second = (m[0] * m[4] - m[1] * m[3]) +
        (m[0] * m[8] - m[2] * m[6]) + (m[4] * m[8] - m[5] * m[7]);
    return .{-trace, second, -det3(m)};
}

fn disc3(a: i64, b: i64, c: i64) i64 {
    return a * a * b * b - 4 * b * b * b - 4 * a * a * a * c - 27 * c * c + 18 * a * b * c;
}

fn rankSingular(m: *const [9]i64, n: usize) usize {
    for (0..n) |r0| {
        for (r0 + 1..n) |r1| {
            for (0..n) |c0| {
                for (c0 + 1..n) |c1| {
                    if (m[r0*n+c0] * m[r1*n+c1] - m[r0*n+c1] * m[r1*n+c0] != 0) return 2;
                }
            }
        }
    }
    for (0..n*n) |i| if (m[i] != 0) return 1;
    return 0;
}

fn shifted(m: *const [9]i64, n: usize, numerator: i64, denominator: i64) [9]i64 {
    var out = [_]i64{0} ** 9;
    for (0..n*n) |i| out[i] = denominator * m[i];
    for (0..n) |i| out[i*n+i] -= numerator;
    return out;
}

fn multiply(a: *const [9]i64, b: *const [9]i64, n: usize) [9]i64 {
    var out = [_]i64{0} ** 9;
    for (0..n) |row| {
        for (0..n) |col| {
            for (0..n) |k| out[row*n+col] += a[row*n+k] * b[k*n+col];
        }
    }
    return out;
}

fn similar(a: *const [9]i64, b: *const [9]i64, n: usize) bool {
    const ca = charpoly(a, n);
    const cb = charpoly(b, n);
    if (ca[0] != cb[0] or ca[1] != cb[1] or ca[2] != cb[2]) return false;
    if (n == 1) return true;
    if (n == 2) {
        if (ca[0] * ca[0] - 4 * ca[1] != 0) return true;
        const da = shifted(a, n, -ca[0], 2);
        const db = shifted(b, n, -ca[0], 2);
        return rankSingular(&da, n) == rankSingular(&db, n);
    }
    if (disc3(ca[0], ca[1], ca[2]) != 0) return true;
    const q = ca[0] * ca[0] - 3 * ca[1];
    if (q == 0) {
        const da = shifted(a, n, -ca[0], 3);
        const db = shifted(b, n, -ca[0], 3);
        if (rankSingular(&da, n) != rankSingular(&db, n)) return false;
        const da2 = multiply(&da, &da, n);
        const db2 = multiply(&db, &db, n);
        return rankSingular(&da2, n) == rankSingular(&db2, n);
    }
    const numerator = 9 * ca[2] - ca[0] * ca[1];
    const denominator = 2 * q;
    const da = shifted(a, n, numerator, denominator);
    const db = shifted(b, n, numerator, denominator);
    return rankSingular(&da, n) == rankSingular(&db, n);
}

pub export fn similar_matrices(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_VALUES) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > 3) return -1;
    const n: usize = @intCast(n_value);
    const matrix_size = n * n;
    if (length != 1 + 2 * matrix_size) return -1;
    var a = [_]i64{0} ** 9;
    var b = [_]i64{0} ** 9;
    for (0..2 * matrix_size) |i| {
        const value = input[1 + i];
        if (value < -5 or value > 5) return -1;
        if (i < matrix_size) a[i] = value else b[i - matrix_size] = value;
    }
    return if (similar(&a, &b, n)) 1 else 0;
}
