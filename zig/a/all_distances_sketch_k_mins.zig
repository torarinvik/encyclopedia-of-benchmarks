const MAX_N: usize = 6;
const MAX_ASSIGNMENTS: usize = 3;
const MAX_INPUT: usize = 27;
const MAX_WORDS: usize = 73;

fn putI64(output: [*c]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[8 * word + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn all_distances_sketch_k_mins(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const n0 = input[0];
    const assignments0 = input[1];
    if (n0 < 1 or n0 > 6 or assignments0 < 1 or assignments0 > 3) return -1;
    const n: usize = @intCast(n0);
    const assignments: usize = @intCast(assignments0);
    if (length != 2 + n + assignments * n) return -1;

    var distances = [_]i64{0} ** MAX_N;
    for (0..n) |item| {
        const distance = input[2 + item];
        if (distance < 0 or distance > 1_000_000
            or (item > 0 and distances[item - 1] >= distance)) return -1;
        distances[item] = distance;
    }
    var ranks = [_][MAX_N]i64{[_]i64{0} ** MAX_N} ** MAX_ASSIGNMENTS;
    for (0..assignments) |assignment| {
        var seen = [_]bool{false} ** MAX_N;
        for (0..n) |item| {
            const rank = input[2 + n + assignment * n + item];
            if (rank < 0 or rank >= n0 or seen[@intCast(rank)]) return -1;
            seen[@intCast(rank)] = true;
            ranks[assignment][item] = rank;
        }
    }

    var staged = [_]i64{0} ** MAX_WORDS;
    var count: usize = 0;
    for (0..assignments) |assignment| {
        var best_rank = n0;
        for (0..n) |item| {
            const rank = ranks[assignment][item];
            if (rank < best_rank) {
                staged[1 + 4 * count] = @intCast(assignment);
                staged[2 + 4 * count] = @intCast(item);
                staged[3 + 4 * count] = rank;
                staged[4 + 4 * count] = distances[item];
                count += 1;
                best_rank = rank;
            }
        }
    }
    staged[0] = @intCast(count);
    const words = 1 + 4 * count;
    const bytes = 8 * words;
    if (output == null or capacity < bytes) return -2;
    for (0..words) |word| putI64(output, word, staged[word]);
    return @intCast(bytes);
}
