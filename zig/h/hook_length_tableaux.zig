// Independent hook-length count; see package README.
const prime: i64 = 998244353;

export fn hook_length_tableaux(input: [*c]const i64, length: usize) i64 {
    if (input == null or length == 0 or input[0] < 0 or input[0] > 65536) return -1;
    const rows: usize = @intCast(input[0]);
    if (length != rows + 1) return -1;
    var total: i64 = 0;
    var previous: i64 = 1000000;
    for (1..rows + 1) |i| {
        const width = input[i];
        if (width < 1 or width > previous) return -1;
        total += width;
        if (total > 1000000) return -1;
        previous = width;
    }
    var hooks: i64 = 1;
    var height = rows;
    if (rows > 0) {
        var col: i64 = 0;
        while (col < input[1]) : (col += 1) {
            while (height > 0 and input[height] <= col) height -= 1;
            for (0..height) |row| {
                const h = input[row + 1] - col + @as(i64, @intCast(height - row - 1));
                hooks = @rem(hooks * h, prime);
            }
        }
    }
    var factorial: i64 = 1;
    var i: i64 = 2;
    while (i <= total) : (i += 1) factorial = @rem(factorial * i, prime);
    var inverse: i64 = 1;
    var exponent: i64 = prime - 2;
    while (exponent > 0) : (exponent >>= 1) {
        if ((exponent & 1) != 0) inverse = @rem(inverse * hooks, prime);
        hooks = @rem(hooks * hooks, prime);
    }
    return @rem(factorial * inverse, prime);
}
