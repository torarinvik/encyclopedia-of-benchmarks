export fn versabench_dbms_penalty(raw: ?[*]const i64, length: usize) i64 {
    if (raw == null or length < 1 or length > 17 or length != 16) return -1;
    const v = raw.?[0..length];
    for (0..2) |box| {
        for (0..4) |d| {
            const lo = v[box * 8 + d]; const hi = v[box * 8 + 4 + d];
            if (lo < -8 or lo > 8 or hi < -8 or hi > 8 or lo >= hi) return -1;
        }
    }
    var joined: i64 = 1;
    var original: i64 = 1;
    for (0..4) |d| {
        joined *= @max(v[4+d], v[12+d]) - @min(v[d], v[8+d]);
        original *= v[4+d] - v[d];
    }
    return joined - original;
}
