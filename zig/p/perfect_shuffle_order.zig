const MAX_DECK_SIZE: i64 = 10_000;
const DECK_CAPACITY: usize = 10_000;
const DECK_STORAGE: usize = 2 * DECK_CAPACITY;

export fn perfect_shuffle_order(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 1) return -1;
    const deck_size_value = input[0];
    if (deck_size_value < 2 or deck_size_value > MAX_DECK_SIZE or @rem(deck_size_value, 2) != 0) return -1;

    const deck_size: usize = @intCast(deck_size_value);
    var decks: [DECK_STORAGE]u16 = @splat(0);
    for (0..deck_size) |index| {
        decks[index] = @intCast(index);
    }

    var current_start: usize = 0;
    var following_start: usize = DECK_CAPACITY;
    const half = deck_size / 2;
    var shuffle_count: i64 = 0;
    while (true) {
        for (0..half) |index| {
            decks[following_start + 2 * index] = decks[current_start + index];
            decks[following_start + 2 * index + 1] = decks[current_start + half + index];
        }
        shuffle_count += 1;

        var restored = true;
        for (0..deck_size) |index| {
            if (decks[following_start + index] != @as(u16, @intCast(index))) {
                restored = false;
                break;
            }
        }
        if (restored) return shuffle_count;

        const temporary = current_start;
        current_start = following_start;
        following_start = temporary;
    }
}
