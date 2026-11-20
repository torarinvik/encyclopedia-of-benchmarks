const MAX_PARSEABLE_LENGTH: usize = 6;
const MAX_DENOMINATION: i64 = 16;
const DISTANCE_INF: i64 = 1_000_000;

fn gcdI64(left_value: i64, right_value: i64) i64 {
    var left = left_value;
    var right = right_value;
    while (right != 0) {
        const remainder = @rem(left, right);
        left = right;
        right = remainder;
    }
    return left;
}

fn aperyFrobenius(coins: []const i64, modulus: usize) i64 {
    var distance: [16]i64 = @splat(DISTANCE_INF);
    var settled: [16]bool = @splat(false);
    distance[0] = 0;
    for (0..modulus) |_| {
        var source: usize = 16;
        var best = DISTANCE_INF;
        for (0..modulus) |residue| {
            if (!settled[residue] and distance[residue] < best) {
                source = residue;
                best = distance[residue];
            }
        }
        if (source == 16) return -1;
        settled[source] = true;
        for (coins) |coin| {
            const target = (source + @as(usize, @intCast(coin))) % modulus;
            const candidate = best + coin;
            if (candidate < distance[target]) distance[target] = candidate;
        }
    }
    var maximum: i64 = 0;
    for (0..modulus) |residue| {
        if (distance[residue] > maximum) maximum = distance[residue];
    }
    return maximum - @as(i64, @intCast(modulus));
}

fn solve(values: []const i64) i64 {
    if (values.len < 1 or values.len > MAX_PARSEABLE_LENGTH) return -1;
    const count_value = values[0];
    if (count_value < 2 or count_value > 4 or values.len != @as(usize, @intCast(count_value + 1))) return -1;
    const coins = values[1..];
    var common: i64 = 0;
    var minimum = MAX_DENOMINATION + 1;
    for (coins, 0..) |coin, index| {
        if (coin < 2 or coin > MAX_DENOMINATION) return -1;
        for (coins[0..index]) |previous| {
            if (coin == previous) return -1;
        }
        common = gcdI64(common, coin);
        if (coin < minimum) minimum = coin;
    }
    if (common != 1) return -1;
    return aperyFrobenius(coins, @as(usize, @intCast(minimum)));
}

export fn frobenius_number_apery(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    return solve(input[0..length]);
}
