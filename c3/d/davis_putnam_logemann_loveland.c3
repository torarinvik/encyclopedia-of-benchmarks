module davis_putnam_logemann_loveland;

const int MAX_VARIABLES = 5;
const int MAX_CLAUSES = 10;
const int MAX_CLAUSE_LENGTH = 5;
const usz MAX_INPUT_LENGTH = 2 + MAX_CLAUSES * (1 + MAX_CLAUSE_LENGTH);

fn bool dpll(uint* positive, uint* negative, int variable_count, int clause_count,
             uint assigned_input, uint truth_input) {
    uint universe = (1u << variable_count) - 1u;
    uint assigned = assigned_input;
    uint truth = truth_input;
    while (true) {
        bool changed = false;
        bool all_satisfied = true;
        for (int clause = 0; clause < clause_count; clause++) {
            uint pos = positive[clause];
            uint neg = negative[clause];
            if ((pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & ~truth)) != 0) continue;
            all_satisfied = false;
            uint open = (pos | neg) & universe & ~assigned;
            if (open == 0) return false;
            if ((open & (open - 1u)) == 0) {
                if ((pos & open) != 0) { truth |= open; }
                else { truth &= ~open; }
                assigned |= open;
                changed = true;
                break;
            }
        }
        if (all_satisfied) return true;
        if (changed) continue;
        uint positive_occurrences = 0;
        uint negative_occurrences = 0;
        for (int clause = 0; clause < clause_count; clause++) {
            uint pos = positive[clause];
            uint neg = negative[clause];
            if ((pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & ~truth)) != 0) continue;
            uint open = (pos | neg) & universe & ~assigned;
            positive_occurrences |= pos & open;
            negative_occurrences |= neg & open;
        }
        uint pure_true = positive_occurrences & ~negative_occurrences;
        uint pure_false = negative_occurrences & ~positive_occurrences;
        uint pure = pure_true | pure_false;
        if (pure != 0) {
            truth = (truth | pure_true) & ~pure_false;
            assigned |= pure;
            continue;
        }
        break;
    }
    for (int variable = 0; variable < variable_count; variable++) {
        uint bit = 1u << variable;
        if ((assigned & bit) == 0) {
            return dpll(positive, negative, variable_count, clause_count, assigned | bit, truth | bit) ||
                   dpll(positive, negative, variable_count, clause_count, assigned | bit, truth & ~bit);
        }
    }
    return false;
}

fn long davis_putnam_logemann_loveland(long* values, usz length)
    @export("davis_putnam_logemann_loveland") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long variable_arg = values[0];
    long clause_arg = values[1];
    if (variable_arg < 0 || variable_arg > MAX_VARIABLES || clause_arg < 0 || clause_arg > MAX_CLAUSES) return -1;
    int variable_count = (int)variable_arg;
    int clause_count = (int)clause_arg;
    uint[MAX_CLAUSES] positive = {0,0,0,0,0,0,0,0,0,0};
    uint[MAX_CLAUSES] negative = {0,0,0,0,0,0,0,0,0,0};
    usz position = 2;
    for (int clause = 0; clause < clause_count; clause++) {
        if (position >= length) return -1;
        long literal_count = values[position++];
        if (literal_count < 0 || literal_count > MAX_CLAUSE_LENGTH || (usz)literal_count > length - position) return -1;
        for (long item = 0; item < literal_count; item++) {
            long literal = values[position++];
            if (literal == 0 || literal < -variable_arg || literal > variable_arg) return -1;
            int variable = (int)(literal < 0 ? -literal : literal);
            uint bit = 1u << (variable - 1);
            if (literal > 0) { positive[clause] |= bit; }
            else { negative[clause] |= bit; }
        }
    }
    if (position != length) return -1;
    return dpll(&positive[0], &negative[0], variable_count, clause_count, 0, 0) ? 1 : 0;
}
