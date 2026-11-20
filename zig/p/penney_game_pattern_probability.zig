const MODULUS: i64 = 998244353;
const MAX_STATES: usize = 7;

fn pow_mod(base_value: i64, exponent_value: i64) i64 {
    var base = base_value;
    var exponent = exponent_value;
    var result: i64 = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn find_state(codes: *const [MAX_STATES]i64, lengths: *const [MAX_STATES]usize,
    count: usize, code: i64, length: usize) ?usize
{
    for (0..count) |index| {
        if (codes[index] == code and lengths[index] == length) return index;
    }
    return null;
}

fn solve(word_length: usize, first: i64, second: i64) i64 {
    var codes: [MAX_STATES]i64 = @splat(0);
    var lengths: [MAX_STATES]usize = @splat(0);
    var state_count: usize = 1;
    for (1..word_length) |prefix_length| {
        for ([_]i64{ first, second }) |pattern| {
            const shift: u6 = @intCast(word_length - prefix_length);
            const code = pattern >> shift;
            if (find_state(&codes, &lengths, state_count, code, prefix_length) == null) {
                codes[state_count] = code;
                lengths[state_count] = prefix_length;
                state_count += 1;
            }
        }
    }

    var matrix: [MAX_STATES][MAX_STATES + 1]i64 = undefined;
    for (0..MAX_STATES) |row| {
        for (0..MAX_STATES + 1) |column| matrix[row][column] = 0;
    }
    for (0..state_count) |row| {
        for (0..state_count) |column| {
            matrix[row][column] = if (row == column) 2 else 0;
        }
        for (0..2) |bit_index| {
            const bit: i64 = @intCast(bit_index);
            const candidate = (codes[row] << 1) | bit;
            const candidate_length = lengths[row] + 1;
            if (candidate_length == word_length and candidate == first) {
                matrix[row][state_count] += 1;
                continue;
            }
            if (candidate_length == word_length and candidate == second) continue;

            var suffix_length = candidate_length;
            if (suffix_length > word_length - 1) suffix_length = word_length - 1;
            var destination: ?usize = null;
            while (true) {
                const shift: u6 = @intCast(suffix_length);
                const suffix_mask = (@as(i64, 1) << shift) - 1;
                destination = find_state(&codes, &lengths, state_count,
                    candidate & suffix_mask, suffix_length);
                if (destination != null or suffix_length == 0) break;
                suffix_length -= 1;
            }
            const target = destination orelse 0;
            matrix[row][target] = (matrix[row][target] - 1 + MODULUS) % MODULUS;
        }
    }

    for (0..state_count) |column| {
        var pivot = column;
        while (pivot < state_count and matrix[pivot][column] == 0) : (pivot += 1) {}
        if (pivot == state_count) return -1;
        if (pivot != column) {
            const temporary = matrix[column];
            matrix[column] = matrix[pivot];
            matrix[pivot] = temporary;
        }
        const inverse = pow_mod(matrix[column][column], MODULUS - 2);
        for (column..state_count + 1) |index|
            matrix[column][index] = matrix[column][index] * inverse % MODULUS;
        for (0..state_count) |row| {
            if (row == column) continue;
            const factor = matrix[row][column];
            for (column..state_count + 1) |index| {
                const product = factor * matrix[column][index] % MODULUS;
                matrix[row][index] = (matrix[row][index] - product + MODULUS) % MODULUS;
            }
        }
    }
    return matrix[0][state_count];
}

pub export fn penney_game_pattern_probability(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const word_length = input[0];
    if (word_length < 1 or word_length > 4) return -1;
    const limit = @as(i64, 1) << @intCast(word_length);
    const first = input[1];
    const second = input[2];
    if (first < 0 or second < 0 or first >= limit or second >= limit or first == second)
        return -1;
    return solve(@intCast(word_length), first, second);
}
