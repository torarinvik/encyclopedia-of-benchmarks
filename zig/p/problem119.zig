const std = @import("std");

fn digitSum(value_in: i64) i64 {
    var value = value_in;
    var sum: i64 = 0;
    while (value > 0) {
        sum += @rem(value, 10);
        value = @divTrunc(value, 10);
    }
    return sum;
}

export fn problem119(index: i64) i64 {
    if (index < 1 or index > 30) return -1;
    var values = [_]i64{0} ** 10000;
    var count: usize = 0;
    for (2..100) |base_u| {
        const base: i64 = @intCast(base_u);
        var value = base * base;
        for (2..100) |_| {
            if (digitSum(value) == base) { values[count] = value; count += 1; }
            if (value > @divTrunc(std.math.maxInt(i64), base)) break;
            value *= base;
        }
    }
    for (1..count) |i| {
        const value = values[i];
        var j = i;
        while (j > 0 and values[j - 1] > value) : (j -= 1) values[j] = values[j - 1];
        values[j] = value;
    }
    return values[@intCast(index - 1)];
}
