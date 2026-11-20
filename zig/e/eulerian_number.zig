/// Return A(n,k), the number of permutations with exactly k descents.
pub export fn eulerian_number(values: [*c]const i64, length: usize) i64 {
    if (values == null or length != 2) return -1;
    const n = values[0];
    const target = values[1];
    if (n < 0 or n > 20 or target < 0
        or (n == 0 and target != 0) or (n > 0 and target >= n)) return -1;

    var previous: [21]i64 = @splat(0);
    var current: [21]i64 = @splat(0);
    previous[0] = 1;
    var row: i64 = 1;
    while (row <= n) : (row += 1) {
        var k: i64 = 0;
        while (k < row) : (k += 1) {
            const same = previous[@intCast(k)];
            const fewer = if (k == 0) 0 else previous[@intCast(k - 1)];
            current[@intCast(k)] = (k + 1) * same + (row - k) * fewer;
        }
        for (0..21) |index| {
            previous[index] = current[index];
            current[index] = 0;
        }
    }
    return previous[@intCast(target)];
}
