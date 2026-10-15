pub export fn find_the_highest_altitude(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or input[0] < 0 or input[0] > 1024 or length != @as(usize, @intCast(input[0])) + 1) return -1;
    const n: usize = @intCast(input[0]);
    var altitude: i64 = 0;
    var maximum: i64 = 0;
    for (0..n) |i| {
        const gain = input[i + 1];
        if (gain < -2147483648 or gain > 2147483647) return -1;
        altitude += gain;
        if (altitude > maximum) maximum = altitude;
    }
    return maximum;
}
