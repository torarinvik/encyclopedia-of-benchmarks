const MAX_TEAMS: usize = 8;
const MAX_PARSEABLE_INPUT: usize = 2;
const MAX_CELLS: usize = 64;

pub export fn round_robin_tournament_schedule(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length == 0 or length > MAX_PARSEABLE_INPUT) return -1;
    if (length != 1) return -1;
    const values = input.?;
    const n_word = values[0];
    if (n_word < 2 or n_word > MAX_TEAMS) return -1;

    const n: usize = @intCast(n_word);
    const padded = n + (n & 1);
    const ring_size = padded - 1;
    const rounds = ring_size;
    const fixed = padded - 1;
    var table = [_]u8{255} ** MAX_CELLS;

    for (0..rounds) |round| {
        if (fixed < n) {
            table[fixed * rounds + round] = @intCast(round);
            table[round * rounds + round] = @intCast(fixed);
        }
        for (1..(padded / 2)) |offset| {
            const left = (round + offset) % ring_size;
            const right = (round + ring_size - offset) % ring_size;
            if (left < n and right < n) {
                table[left * rounds + round] = @intCast(right);
                table[right * rounds + round] = @intCast(left);
            }
        }
    }

    const required = 2 + n * rounds;
    if (output == null or capacity < required) return -2;
    const bytes = output.?;
    bytes[0] = @intCast(n);
    bytes[1] = @intCast(rounds);
    for (0..n * rounds) |i| bytes[i + 2] = table[i];
    return @intCast(required);
}
