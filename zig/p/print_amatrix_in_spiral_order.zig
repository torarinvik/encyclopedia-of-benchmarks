fn mix(h0: u32, x: i64) u32 {
    var h = h0; const u: u32 = @bitCast(@as(i32, @intCast(x)));
    for (0..4) |i| h = (h ^ ((u >> @intCast(i * 8)) & 255)) *% 16777619;
    return h;
}
export fn print_amatrix_in_spiral_order(v: [*]const i64, n: usize) i64 {
    if (n < 3 or n > 66 or v[0] < 1 or v[0] > 8 or v[1] < 1 or v[1] > 8 or n != 2 + @as(usize, @intCast(v[0] * v[1]))) return -1;
    const rows: usize = @intCast(v[0]); const cols: usize = @intCast(v[1]);
    for (2..n) |i| if (v[i] < -2147483648 or v[i] > 2147483647) return -1;
    var top: usize = 0; var bottom = rows - 1; var left: usize = 0; var right = cols - 1; var h: u32 = 2166136261;
    while (top <= bottom and left <= right) {
        for (left..right + 1) |c| h = mix(h, v[2 + top * cols + c]);
        top += 1;
        for (top..bottom + 1) |r| h = mix(h, v[2 + r * cols + right]);
        if (right == 0) break; right -= 1;
        if (top <= bottom) { var c = right + 1; while (c > left) { c -= 1; h = mix(h, v[2 + bottom * cols + c]); } if (bottom == 0) break; bottom -= 1; }
        if (left <= right) { var r = bottom + 1; while (r > top) { r -= 1; h = mix(h, v[2 + r * cols + left]); } left += 1; }
    }
    return @intCast(h);
}
