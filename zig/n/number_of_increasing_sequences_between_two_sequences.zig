// Clean-room bounded implementation of the Library Checker sequence-counting task.
const MAX_N: usize = 64;
const MAX_M: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MOD: i64 = 998244353;

export fn number_of_increasing_sequences_between_two_sequences(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const n_value = input[0];
    const m_value = input[1];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or m_value < 1 or m_value > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(n_value);
    const m: usize = @intCast(m_value);
    if (length != 2 + 2 * n) return -1;
    var lower: [MAX_N]i64 = @splat(0);
    var upper: [MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        lower[i] = input[2 + i];
        upper[i] = input[2 + n + i];
        if (lower[i] < 0 or lower[i] >= upper[i] or upper[i] > m_value) return -1;
    }
    var previous: [MAX_M]i64 = @splat(0);
    var current: [MAX_M]i64 = @splat(0);
    const first: usize = @intCast(lower[0]);
    const last: usize = @intCast(upper[0]);
    for (first..last) |value| previous[value] = 1;
    for (1..n) |position| {
        var prefix: i64 = 0;
        for (0..m) |value| {
            prefix += previous[value];
            if (prefix >= MOD) prefix -= MOD;
            current[value] = if (lower[position] <= @as(i64, @intCast(value)) and @as(i64, @intCast(value)) < upper[position]) prefix else 0;
        }
        const temporary = previous;
        previous = current;
        current = temporary;
    }
    var answer: i64 = 0;
    for (0..m) |value| {
        answer += previous[value];
        if (answer >= MOD) answer -= MOD;
    }
    return answer;
}
