const MAX_TOTAL: usize = 36;
const SCALE: i64 = 10_000_000;

fn distribution(sides: usize, dice: usize, output: []i64) void {
    var current: [37]i64 = @splat(0);
    current[0] = 1;
    for (0..dice) |_| {
        var next: [37]i64 = @splat(0);
        for (0..MAX_TOTAL + 1) |total| {
            if (current[total] == 0) continue;
            for (1..sides + 1) |face| next[total + face] += current[total];
        }
        current = next;
    }
    @memcpy(output, current[0..]);
}

export fn problem205(placeholder: i64) i64 {
    if (placeholder != 0) return -1;
    var peter: [37]i64 = @splat(0);
    var colin: [37]i64 = @splat(0);
    distribution(4, 9, peter[0..]);
    distribution(6, 6, colin[0..]);
    var wins: i64 = 0;
    var colin_below: i64 = 0;
    for (0..MAX_TOTAL + 1) |total| {
        if (total >= 9) wins += peter[total] * colin_below;
        colin_below += colin[total];
    }
    const games: i64 = 262_144 * 46_656;
    const scaled = wins * SCALE;
    var rounded = @divTrunc(scaled, games);
    const remainder = @rem(scaled, games);
    if (2 * remainder > games or (2 * remainder == games and @rem(rounded, 2) != 0)) rounded += 1;
    return rounded;
}
