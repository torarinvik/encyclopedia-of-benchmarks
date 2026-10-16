/// Count equal-value index pairs with a bounded open-addressed frequency table.
const TABLE_SIZE: usize = 512;
const MAX_INPUT_LENGTH: usize = 258;

export fn good_pairs_hash(input: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH or input == null) return -1;
    const input_values = input.?;
    const declared = input_values[0];
    if (declared < 0 or declared > 256 or length != @as(usize, @intCast(declared)) + 1) return -1;
    const n: usize = @intCast(declared);
    var keys = [_]i64{0} ** TABLE_SIZE;
    var frequencies = [_]u64{0} ** TABLE_SIZE;
    var occupied = [_]bool{false} ** TABLE_SIZE;
    for (0..n) |index| {
        const value = input_values[index + 1];
        if (value < -1000000 or value > 1000000) return -1;
        var slot: usize = @intCast(@mod((value + 1000000) * 2654435761, 512));
        while (occupied[slot] and keys[slot] != value) slot = (slot + 1) & (TABLE_SIZE - 1);
        if (!occupied[slot]) { occupied[slot] = true; keys[slot] = value; }
        frequencies[slot] += 1;
    }
    var pairs: u64 = 0;
    for (frequencies) |frequency| {
        if (frequency > 1) pairs += frequency * (frequency - 1) / 2;
    }
    return @intCast(pairs);
}
