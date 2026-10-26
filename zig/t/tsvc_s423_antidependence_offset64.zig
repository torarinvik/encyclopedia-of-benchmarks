const std = @import("std");

export fn tsvc_s423_antidependence_offset64(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 130 or length > 193) return -1;
    const input = input_opt.?;
    if (input[0] < 65 or input[0] > 128) return -1;
    const n: usize = @intCast(input[0]);
    if (length != n + 65) return -1;
    var a = [_]i64{0} ** 128;
    var x = [_]i64{0} ** 192;
    for (0..n) |i| {
        a[i] = input[1+i];
        if (a[i] < 0 or a[i] > 2) return -1;
    }
    for (0..64) |i| {
        x[i] = input[1+n+i];
        if (x[i] < 0 or x[i] > 2) return -1;
    }
    for (64..n+64) |i| x[i] = 1;
    for (0..n-1) |i| x[i+1] = x[i+64] + a[i];
    var total: i64 = 0;
    for (0..n) |i| total += x[i];
    return total;
}
