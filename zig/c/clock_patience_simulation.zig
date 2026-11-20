pub export fn clock_patience_simulation(values: ?[*]const i64, length: usize) callconv(.c) i64 {
    const pile_count: usize = 13;
    const cards_per_pile: usize = 4;
    const card_count = pile_count * cards_per_pile;
    const cards = values orelse return -1;
    if (length != card_count) return -1;

    var rank_counts = [_]usize{0} ** (pile_count + 1);
    for (0..card_count) |index| {
        const rank = cards[index];
        if (rank < 1 or rank > 13) return -1;
        rank_counts[@intCast(rank)] += 1;
    }
    for (1..pile_count + 1) |rank| {
        if (rank_counts[rank] != cards_per_pile) return -1;
    }

    var next_card = [_]usize{0} ** pile_count;
    var pile = pile_count - 1;
    var revealed: usize = 0;
    while (next_card[pile] < cards_per_pile) {
        const rank = cards[pile * cards_per_pile + next_card[pile]];
        next_card[pile] += 1;
        revealed += 1;
        pile = @intCast(rank - 1);
    }
    return if (revealed == card_count) 1 else 0;
}
