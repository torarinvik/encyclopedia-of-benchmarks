fn mix(h: u32, b: u8) u32 { return (h ^ b) *% 16777619; }
fn nextPerm(a: *[7]u8, n: usize) bool {
    var i = n - 1;
    while (i > 0 and a[i - 1] >= a[i]) : (i -= 1) {}
    if (i == 0) return false;
    var j = n - 1;
    while (a[j] <= a[i - 1]) : (j -= 1) {}
    const t = a[i - 1]; a[i - 1] = a[j]; a[j] = t;
    var left = i; var right = n - 1;
    while (left < right) : ({ left += 1; right -= 1; }) { const x = a[left]; a[left] = a[right]; a[right] = x; }
    return true;
}
export fn permutate_string(v: [*c]const i64, n: usize) i64 {
    if (v == null or n < 2 or n > 8 or v[0] < 1 or v[0] > 7 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    const len: usize = @intCast(v[0]); var a: [7]u8 = undefined;
    for (0..len) |i| { if (v[i + 1] < 33 or v[i + 1] > 126) return -1; a[i] = @intCast(v[i + 1]); for (0..i) |j| { if (a[j] == a[i]) return -1; } }
    for (1..len) |i| { var j = i; while (j > 0 and a[j - 1] > a[j]) : (j -= 1) { const t = a[j - 1]; a[j - 1] = a[j]; a[j] = t; } }
    var h: u32 = 2166136261;
    while (true) { for (a[0..len]) |b| h = mix(h, b); h = mix(h, 0); if (!nextPerm(&a, len)) break; }
    return @intCast(h);
}
const std = @import("std");
