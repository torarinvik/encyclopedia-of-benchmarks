export fn maximum_ice_cream_bars(input: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 257) return -1;
    const coins = input[0];
    const count = length - 1;
    if (coins < 0 or coins > 1_000_000) return -1;
    var costs: [256]i64 = @splat(0);
    for (0..count) |index| {
        const cost = input[index + 1];
        if (cost < 1 or cost > 10_000) return -1;
        var position = index;
        while (position > 0 and costs[position - 1] > cost) : (position -= 1) {
            costs[position] = costs[position - 1];
        }
        costs[position] = cost;
    }
    var remaining = coins;
    var bought: i64 = 0;
    for (0..count) |index| {
        if (costs[index] > remaining) break;
        remaining -= costs[index];
        bought += 1;
    }
    return bought;
}
