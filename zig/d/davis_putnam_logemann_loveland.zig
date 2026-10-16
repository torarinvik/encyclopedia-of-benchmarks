const MAX_VARIABLES: usize = 5;
const MAX_CLAUSES: usize = 10;
const MAX_CLAUSE_LENGTH: usize = 5;
const MAX_INPUT_LENGTH: usize = 2 + MAX_CLAUSES * (1 + MAX_CLAUSE_LENGTH);

fn dpll(positive: *const [MAX_CLAUSES]u8, negative: *const [MAX_CLAUSES]u8,
    variable_count: usize, clause_count: usize, assigned_input: u8, truth_input: u8) bool {
    const universe: u8 = @intCast((@as(u16, 1) << @intCast(variable_count)) - 1);
    var assigned = assigned_input;
    var truth = truth_input;
    while (true) {
        var changed = false;
        var all_satisfied = true;
        for (0..clause_count) |clause| {
            const pos = positive[clause];
            const neg = negative[clause];
            if ((pos & neg) != 0 or (pos & truth) != 0 or (neg & (assigned & ~truth)) != 0) continue;
            all_satisfied = false;
            const open = (pos | neg) & universe & ~assigned;
            if (open == 0) return false;
            if ((open & (open - 1)) == 0) {
                if ((pos & open) != 0) truth |= open else truth &= ~open;
                assigned |= open;
                changed = true;
                break;
            }
        }
        if (all_satisfied) return true;
        if (changed) continue;
        var positive_occurrences: u8 = 0;
        var negative_occurrences: u8 = 0;
        for (0..clause_count) |clause| {
            const pos = positive[clause];
            const neg = negative[clause];
            if ((pos & neg) != 0 or (pos & truth) != 0 or (neg & (assigned & ~truth)) != 0) continue;
            const open = (pos | neg) & universe & ~assigned;
            positive_occurrences |= pos & open;
            negative_occurrences |= neg & open;
        }
        const pure_true = positive_occurrences & ~negative_occurrences;
        const pure_false = negative_occurrences & ~positive_occurrences;
        const pure = pure_true | pure_false;
        if (pure != 0) {
            truth = (truth | pure_true) & ~pure_false;
            assigned |= pure;
            continue;
        }
        break;
    }
    for (0..variable_count) |variable| {
        const bit: u8 = @intCast(@as(u16, 1) << @intCast(variable));
        if ((assigned & bit) == 0)
            return dpll(positive, negative, variable_count, clause_count, assigned | bit, truth | bit) or
                dpll(positive, negative, variable_count, clause_count, assigned | bit, truth & ~bit);
    }
    return false;
}

export fn davis_putnam_logemann_loveland(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = values.?[0..length];
    const variable_arg = input[0];
    const clause_arg = input[1];
    if (variable_arg < 0 or variable_arg > MAX_VARIABLES or clause_arg < 0 or clause_arg > MAX_CLAUSES) return -1;
    const variable_count: usize = @intCast(variable_arg);
    const clause_count: usize = @intCast(clause_arg);
    var positive: [MAX_CLAUSES]u8 = undefined;
    @memset(&positive, 0);
    var negative: [MAX_CLAUSES]u8 = undefined;
    @memset(&negative, 0);
    var position: usize = 2;
    for (0..clause_count) |clause| {
        if (position >= length) return -1;
        const literal_count = input[position];
        position += 1;
        if (literal_count < 0 or literal_count > MAX_CLAUSE_LENGTH or @as(usize, @intCast(literal_count)) > length - position) return -1;
        for (0..@intCast(literal_count)) |_| {
            const literal = input[position];
            position += 1;
            if (literal == 0 or literal < -variable_arg or literal > variable_arg) return -1;
            const variable: usize = @intCast(if (literal < 0) -literal else literal);
            const bit: u8 = @intCast(@as(u16, 1) << @intCast(variable - 1));
            if (literal > 0) positive[clause] |= bit else negative[clause] |= bit;
        }
    }
    if (position != length) return -1;
    return if (dpll(&positive, &negative, variable_count, clause_count, 0, 0)) 1 else 0;
}
