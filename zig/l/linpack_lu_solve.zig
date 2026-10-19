// ANSIbench LINPACK dgefa/dgesl profile; upstream source and stated modifications are public domain.
const INVALID_RESULT: f64 = -1.0e300;

pub export fn linpack_lu_solve(input: ?[*]const i64, length: usize) callconv(.c) f64 {
    if (input == null or length < 1 or length > 22) return INVALID_RESULT;
    const values = input orelse return INVALID_RESULT;
    const raw_n = values[0];
    if (raw_n < 2 or raw_n > 4) return INVALID_RESULT;
    const n: usize = @intCast(raw_n);
    if (length != 1 + n*n + n) return INVALID_RESULT;
    var a = [_]f64{0} ** 16;
    var b = [_]f64{0} ** 4;
    var pivots = [_]usize{0} ** 4;
    for (0..n*n) |i| {
        const value = values[1+i];
        if (value < -8 or value > 8) return INVALID_RESULT;
        a[i] = @floatFromInt(value);
    }
    for (0..n) |i| {
        const value = values[1+n*n+i];
        if (value < -32 or value > 32) return INVALID_RESULT;
        b[i] = @floatFromInt(value);
    }
    for (0..n-1) |k| {
        var l = k;
        var maximum = @abs(a[n*k+k]);
        for (1..n-k) |offset| {
            const candidate = @abs(a[n*k+k+offset]);
            if (candidate > maximum) { l=k+offset; maximum=candidate; }
        }
        pivots[k]=l;
        if (a[n*k+l] == 0) return INVALID_RESULT;
        if (l != k) { const t=a[n*k+l]; a[n*k+l]=a[n*k+k]; a[n*k+k]=t; }
        const factor = -1.0/a[n*k+k];
        for (0..n-k-1) |i| a[n*k+k+1+i]=factor*a[n*k+k+1+i];
        for (k+1..n) |j| {
            var t=a[n*j+l];
            if (l!=k) { a[n*j+l]=a[n*j+k]; a[n*j+k]=t; }
            if (t != 0) for (0..n-k-1) |i| a[n*j+k+1+i]=a[n*j+k+1+i]+t*a[n*k+k+1+i];
        }
    }
    pivots[n-1]=n-1;
    if (a[n*(n-1)+n-1] == 0) return INVALID_RESULT;
    for (0..n-1) |k| {
        const l=pivots[k]; const t=b[l];
        if (l!=k) { b[l]=b[k]; b[k]=t; }
        if (t != 0) for (0..n-k-1) |i| b[k+1+i]=b[k+1+i]+t*a[n*k+k+1+i];
    }
    for (0..n) |kb| {
        const k=n-(kb+1);
        b[k]=b[k]/a[n*k+k]; const t=-b[k];
        if (t != 0) for (0..k) |i| b[i]=b[i]+t*a[n*k+i];
    }
    var result: f64=0;
    for (0..n) |i| result=result+@as(f64,@floatFromInt(i+1))*b[i];
    if (!@import("std").math.isFinite(result)) return INVALID_RESULT;
    return result;
}
