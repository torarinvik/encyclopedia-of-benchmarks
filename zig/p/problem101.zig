fn questionFunction(n: i64) i64 {
    var term: i64 = 1;
    var total: i64 = 0;
    for (0..11) |exponent| {
        if (exponent % 2 == 0) total += term else total -= term;
        term *= n;
    }
    return total;
}

export fn problem101(order: i64) i64 {
    if (order > 10) return -1;
    if (order <= 0) return 0;
    const count: usize = @intCast(order);
    var data = [_]i64{0} ** 10;
    for (0..count) |i| data[i] = questionFunction(@intCast(i + 1));
    var total_fit: i64 = 0;
    for (1..(count + 1)) |k| {
        var row = [_]i64{0} ** 10;
        var differences = [_]i64{0} ** 10;
        for (0..k) |i| row[i] = data[i];
        differences[0] = row[0];
        for (1..k) |level| {
            for (0..(k - level)) |i| row[i] = row[i + 1] - row[i];
            differences[level] = row[0];
        }
        var x: i64 = 1;
        while (true) {
            var prediction: i64 = 0;
            var choose: i64 = 1;
            for (0..k) |j| {
                prediction += differences[j] * choose;
                if (j + 1 < k) choose = choose * (x - 1 - @as(i64, @intCast(j))) / @as(i64, @intCast(j + 1));
            }
            if (prediction != questionFunction(x)) {
                total_fit += prediction;
                break;
            }
            x += 1;
        }
    }
    return total_fit;
}
