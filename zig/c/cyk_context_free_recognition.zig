const MAX_NONTERMINALS: i64 = 4;
const MAX_TERMINALS: i64 = 2;
const MAX_WORD_LENGTH: i64 = 8;
const MAX_PRODUCTIONS: i64 = 12;
const MAX_INPUT_LENGTH: usize = 62;

export fn cyk_context_free_recognition(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const variables_value = input[0];
    const alphabet_value = input[1];
    const word_value = input[2];
    const rule_value = input[3];
    const start_value = input[4];
    if (variables_value < 1 or variables_value > MAX_NONTERMINALS or
        alphabet_value < 1 or alphabet_value > MAX_TERMINALS or
        word_value < 1 or word_value > MAX_WORD_LENGTH or
        rule_value < 0 or rule_value > MAX_PRODUCTIONS or
        start_value < 0 or start_value >= variables_value) return -1;
    const word_length: usize = @intCast(word_value);
    const rule_count: usize = @intCast(rule_value);
    if (length != 5 + word_length + 4 * rule_count) return -1;
    for (0..word_length) |position| {
        const token = input[5 + position];
        if (token < 0 or token >= alphabet_value) return -1;
    }
    const rules = 5 + word_length;
    for (0..rule_count) |rule| {
        const offset = rules + 4 * rule;
        const kind = input[offset];
        const lhs = input[offset + 1];
        const first = input[offset + 2];
        const second = input[offset + 3];
        if (lhs < 0 or lhs >= variables_value) return -1;
        if (kind == 0) {
            if (first < 0 or first >= alphabet_value or second != 0) return -1;
        } else if (kind == 1) {
            if (first < 0 or first >= variables_value or second < 0 or second >= variables_value)
                return -1;
        } else return -1;
    }

    var chart: [4 * 8 * 9]bool = @splat(false);
    for (0..word_length) |position| {
        const token = input[5 + position];
        for (0..rule_count) |rule| {
            const offset = rules + 4 * rule;
            if (input[offset] == 0 and input[offset + 2] == token) {
                const cell = @as(usize, @intCast(input[offset + 1])) * 72 + position * 9 + 1;
                chart[cell] = true;
            }
        }
    }
    for (2..word_length + 1) |width| {
        for (0..word_length - width + 1) |left| {
            for (0..rule_count) |rule| {
                const offset = rules + 4 * rule;
                if (input[offset] != 1) continue;
                const lhs: usize = @intCast(input[offset + 1]);
                const first: usize = @intCast(input[offset + 2]);
                const second: usize = @intCast(input[offset + 3]);
                for (1..width) |split| {
                    const left_cell = first * 72 + left * 9 + split;
                    const right_cell = second * 72 + (left + split) * 9 + width - split;
                    if (chart[left_cell] and chart[right_cell]) {
                        chart[lhs * 72 + left * 9 + width] = true;
                        break;
                    }
                }
            }
        }
    }
    const start: usize = @intCast(start_value);
    return if (chart[start * 72 + word_length]) 1 else 0;
}
