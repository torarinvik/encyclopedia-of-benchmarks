const MAX_TOTAL: usize = 200;
const MAX_PARTS: usize = 200;
const MEMO_SIZE: usize = (MAX_TOTAL + 1) * MAX_PARTS;

pub export fn problem76(total: i64) i64 {
    if (total < 1 or total > MAX_TOTAL) return -1;
    const bound: usize = @intCast(total);
    var memo = [_]i64{0} ** MEMO_SIZE;
    for (0..bound + 1) |n| memo[n * MAX_PARTS] = 1;
    for (0..bound + 1) |n| {
        var k: usize = 1;
        while (k < bound) : (k += 1) {
            const index = n * MAX_PARTS + k;
            memo[index] += memo[index - 1];
            if (n > k) memo[index] += memo[(n - k - 1) * MAX_PARTS + k];
        }
    }
    return memo[bound * MAX_PARTS + bound - 1] - 1;
}
