const MAX_N: usize = 6;
const MAX_SWEEPS: usize = 128;
const TOL: f64 = 1.0e-14;

export fn one_sided_jacobi_svd(input: ?[*]const i64, length: usize) i64 {
    const values = input orelse return -1;
    if (length < 3 or length > 39) return -1;
    const m64, n64 = .{ values[0], values[1] };
    if (n64 < 1 or n64 > MAX_N or m64 < n64 or m64 > MAX_N) return -1;
    const m: usize = @intCast(m64);
    const n: usize = @intCast(n64);
    if (length != 2 + m * n) return -1;
    var a = [_]f64{0.0} ** 36;
    for (0..m) |r| for (0..n) |col| {
        const x = values[2 + r * n + col];
        if (x < -8 or x > 8) return -1;
        a[r * n + col] = @floatFromInt(x);
    };
    var converged = false;
    for (0..MAX_SWEEPS) |_| {
        var changed = false;
        for (0..n) |p| for (p + 1..n) |q| {
            var alpha: f64 = 0;
            var beta: f64 = 0;
            var gamma: f64 = 0;
            for (0..m) |r| { const x=a[r*n+p];const y=a[r*n+q];alpha+=x*x;beta+=y*y;gamma+=x*y; }
            if (alpha == 0 or beta == 0 or @abs(gamma) <= TOL * @sqrt(alpha * beta)) continue;
            const tau = (beta - alpha) / (2.0 * gamma);
            const sign: f64 = if (tau > 0) 1.0 else if (tau < 0) -1.0 else 1.0;
            const t = if (tau == 0) 1.0 else sign / (@abs(tau) + @sqrt(1.0 + tau*tau));
            const c = 1.0 / @sqrt(1.0 + t*t);
            const s = c*t;
            for (0..m) |r| { const x=a[r*n+p];const y=a[r*n+q];a[r*n+p]=c*x-s*y;a[r*n+q]=s*x+c*y; }
            changed = true;
        };
        if (!changed) { converged = true; break; }
    }
    if (!converged) return -1;
    var sigma = [_]f64{0.0} ** MAX_N;
    for (0..n) |col| { for (0..m) |r| sigma[col] += a[r*n+col] * a[r*n+col]; sigma[col] = @sqrt(sigma[col]); }
    for (0..n) |i| for (i + 1..n) |j| { if (sigma[j] > sigma[i]) { const t=sigma[i];sigma[i]=sigma[j];sigma[j]=t; } };
    var signature: f64 = 0;
    for (0..n) |i| signature += @as(f64, @floatFromInt(i + 1)) * sigma[i];
    return @intFromFloat(signature * 1000.0 + 0.5);
}
