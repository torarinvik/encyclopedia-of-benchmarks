/// Proposer-proposing Gale-Shapley stable matching for complete preferences.
pub export fn gale_shapley(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 66) return -2;
    if (values[0] < 0 or values[0] > 5) return -2;
    const count: usize = @intCast(values[0]);
    if (length != 1 + 2 * count * count) return -2;
    var ranks: [5][5]i64 = @splat(@splat(0));
    var seen: [5]bool = @splat(false);
    for (0..count) |proposer| {
        @memset(seen[0..count], false);
        for (0..count) |rank| {
            const accepter_value = values[1 + proposer * count + rank];
            if (accepter_value < 0 or @as(u64, @intCast(accepter_value)) >= count) return -2;
            const accepter: usize = @intCast(accepter_value);
            if (seen[accepter]) return -2;
            seen[accepter] = true;
        }
    }
    const accepter_offset = 1 + count * count;
    for (0..count) |accepter| {
        @memset(seen[0..count], false);
        for (0..count) |rank| {
            const proposer_value = values[accepter_offset + accepter * count + rank];
            if (proposer_value < 0 or @as(u64, @intCast(proposer_value)) >= count) return -2;
            const proposer: usize = @intCast(proposer_value);
            if (seen[proposer]) return -2;
            seen[proposer] = true;
            ranks[accepter][proposer] = @intCast(rank);
        }
    }
    if (output_capacity < count) return -2;
    var matched_proposer: [5]i64 = @splat(-1);
    var matched_accepter: [5]i64 = @splat(-1);
    var next_choice: [5]usize = @splat(0);
    while (true) {
        var proposer: usize = 0;
        while (proposer < count and matched_accepter[proposer] != -1) : (proposer += 1) {}
        if (proposer == count) break;
        const accepter: usize = @intCast(values[1 + proposer * count + next_choice[proposer]]);
        next_choice[proposer] += 1;
        const current = matched_proposer[accepter];
        if (current == -1 or ranks[accepter][proposer] < ranks[accepter][@intCast(current)]) {
            if (current != -1) matched_accepter[@intCast(current)] = -1;
            matched_proposer[accepter] = @intCast(proposer);
            matched_accepter[proposer] = @intCast(accepter);
        }
    }
    for (0..count) |proposer| output[proposer] = @intCast(matched_accepter[proposer]);
    return @intCast(count);
}
