const MAX_LENGTH: usize = 4096;

pub export fn count_nice_subarrays(values: [*]const i64, length: usize) i64 {
    if (length < 2 or values[0] < 0 or values[0] > MAX_LENGTH or values[1] < 1 or values[1] > MAX_LENGTH) return -1;
    const n: usize = @intCast(values[0]);
    const k: i32 = @intCast(values[1]);
    if (length != n + 2) return -1;
    for (values[2..length]) |value| if (value < -2147483648 or value > 2147483647) return -1;
    var memo: [MAX_LENGTH]i32 = @splat(0);
    var left: usize = 0;
    var odd_count: i32 = 0;
    var result: i64 = 0;
    for (0..n) |right| {
        if ((@as(i32, @intCast(values[right + 2])) & 1) == 1) odd_count += 1;
        if (odd_count > k) {
            left += @intCast(memo[left]);
            odd_count -= 1;
        }
        if (odd_count == k) {
            if (memo[left] == 0) {
                var even_count: usize = 0;
                var temp = left;
                while ((@as(i32, @intCast(values[temp + 2])) & 1) == 0) {
                    even_count += 1;
                    temp += 1;
                }
                memo[left] = @intCast(even_count + 1);
            }
            result += @as(i64, memo[left]);
        }
    }
    return result;
}
