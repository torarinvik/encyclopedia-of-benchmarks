export fn pig_latin(v: [*c]const i64, n: usize, out: [*c]u8, cap: usize) i64 {
    if (v == null or n < 1 or n > 65 or v[0] < 0 or v[0] > 64 or n != @as(usize, @intCast(v[0])) + 1) return -1;
    const count: usize = @intCast(v[0]); if (count == 0) return 0; if (count + 3 > cap or out == null) return -2;
    var pivot = count;
    for (0..count) |i| { var x = v[i + 1]; if (x >= 65 and x <= 90) x += 32; if (x < 97 or x > 122) return -1; out[i] = @intCast(x); if (pivot == count and (x == 97 or x == 101 or x == 105 or x == 111 or x == 117)) pivot = i; }
    if (pivot == count) return -1;
    if (pivot == 0) { out[count] = 'w'; out[count + 1] = 'a'; out[count + 2] = 'y'; return @intCast(count + 3); }
    for (0..pivot) |i| out[count + i] = out[i];
    for (0..count - pivot) |i| out[i] = out[pivot + i];
    out[count] = 'a'; out[count + 1] = 'y'; return @intCast(count + 2);
}
