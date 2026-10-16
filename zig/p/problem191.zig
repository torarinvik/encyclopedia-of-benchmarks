export fn problem191(days: i64) i64 {
    if (days < 0 or days > 65) return -1;
    var ways = [_]i64{0} ** 396;
    for (0..2) |absent| {
        for (0..3) |late| ways[absent * 3 + late] = 1;
    }
    const day_count: usize = @intCast(days);
    for (1..(day_count + 1)) |remaining| {
        for (0..2) |absent| {
            for (0..3) |late| {
                const previous = (remaining - 1) * 6;
                const late_state: i64 = if (late < 2) ways[previous + absent * 3 + late + 1] else 0;
                const absent_state: i64 = if (absent == 0) ways[previous + 3] else 0;
                const on_time_state = ways[previous + absent * 3];
                ways[remaining * 6 + absent * 3 + late] = late_state + absent_state + on_time_state;
            }
        }
    }
    return ways[day_count * 6];
}
