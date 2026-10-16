export fn problem109(limit: i64) i64 {
    var values = [_]i64{0} ** 63;
    var doubles = [_]i64{0} ** 21;
    var value_count: usize = 0;
    var double_count: usize = 0;
    for (1..21) |score| { values[value_count] = @intCast(score); value_count += 1; }
    values[value_count] = 25; value_count += 1;
    for (1..21) |score| { doubles[double_count] = 2 * @as(i64, @intCast(score)); values[value_count] = doubles[double_count]; double_count += 1; value_count += 1; }
    doubles[double_count] = 50; values[value_count] = 50; double_count += 1; value_count += 1;
    for (1..21) |score| { values[value_count] = 3 * @as(i64, @intCast(score)); value_count += 1; }
    values[value_count] = 0; value_count += 1;
    var count: i64 = 0;
    for (0..double_count) |d| {
        for (0..value_count) |first| {
            for (first..value_count) |second| {
                if (doubles[d] + values[first] + values[second] < limit) count += 1;
            }
        }
    }
    return count;
}
