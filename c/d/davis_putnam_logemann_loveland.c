#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VARIABLES 5
#define MAX_CLAUSES 10
#define MAX_CLAUSE_LENGTH 5
#define MAX_INPUT_LENGTH (2 + MAX_CLAUSES * (1 + MAX_CLAUSE_LENGTH))

static bool dpll(const uint8_t positive[MAX_CLAUSES], const uint8_t negative[MAX_CLAUSES],
                 int variable_count, int clause_count, uint8_t assigned, uint8_t truth) {
    const uint8_t universe = (uint8_t)((1u << variable_count) - 1u);
    for (;;) {
        bool changed = false;
        bool all_satisfied = true;
        for (int clause = 0; clause < clause_count; ++clause) {
            const uint8_t pos = positive[clause], neg = negative[clause];
            if ((pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & (uint8_t)~truth)) != 0) continue;
            all_satisfied = false;
            const uint8_t open = (uint8_t)((pos | neg) & universe & (uint8_t)~assigned);
            if (open == 0) return false;
            if ((open & (uint8_t)(open - 1u)) == 0) {
                if ((pos & open) != 0) truth |= open;
                else truth &= (uint8_t)~open;
                assigned |= open;
                changed = true;
                break;
            }
        }
        if (all_satisfied) return true;
        if (changed) continue;

        uint8_t positive_occurrences = 0, negative_occurrences = 0;
        for (int clause = 0; clause < clause_count; ++clause) {
            const uint8_t pos = positive[clause], neg = negative[clause];
            if ((pos & neg) != 0 || (pos & truth) != 0 || (neg & (assigned & (uint8_t)~truth)) != 0) continue;
            const uint8_t open = (uint8_t)((pos | neg) & universe & (uint8_t)~assigned);
            positive_occurrences |= (uint8_t)(pos & open);
            negative_occurrences |= (uint8_t)(neg & open);
        }
        const uint8_t pure_true = (uint8_t)(positive_occurrences & (uint8_t)~negative_occurrences);
        const uint8_t pure_false = (uint8_t)(negative_occurrences & (uint8_t)~positive_occurrences);
        const uint8_t pure = (uint8_t)(pure_true | pure_false);
        if (pure != 0) {
            truth = (uint8_t)((truth | pure_true) & (uint8_t)~pure_false);
            assigned |= pure;
            continue;
        }
        break;
    }

    for (int variable = 0; variable < variable_count; ++variable) {
        const uint8_t bit = (uint8_t)(1u << variable);
        if ((assigned & bit) == 0)
            return dpll(positive, negative, variable_count, clause_count, (uint8_t)(assigned | bit),
                        (uint8_t)(truth | bit)) ||
                   dpll(positive, negative, variable_count, clause_count, (uint8_t)(assigned | bit),
                        (uint8_t)(truth & (uint8_t)~bit));
    }
    return false;
}

int64_t davis_putnam_logemann_loveland(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t variable_arg = values[0], clause_arg = values[1];
    if (variable_arg < 0 || variable_arg > MAX_VARIABLES || clause_arg < 0 || clause_arg > MAX_CLAUSES) return -1;
    const int variable_count = (int)variable_arg, clause_count = (int)clause_arg;
    uint8_t positive[MAX_CLAUSES] = {0}, negative[MAX_CLAUSES] = {0};
    size_t position = 2;
    for (int clause = 0; clause < clause_count; ++clause) {
        if (position >= length) return -1;
        const int64_t literal_count = values[position++];
        if (literal_count < 0 || literal_count > MAX_CLAUSE_LENGTH || (size_t)literal_count > length - position) return -1;
        for (int64_t item = 0; item < literal_count; ++item) {
            const int64_t literal = values[position++];
            if (literal == 0 || literal < -variable_count || literal > variable_count) return -1;
            const uint8_t bit = (uint8_t)(1u << (unsigned)(literal < 0 ? -literal : literal) - 1u);
            if (literal > 0) positive[clause] |= bit;
            else negative[clause] |= bit;
        }
    }
    if (position != length) return -1;
    return dpll(positive, negative, variable_count, clause_count, 0, 0) ? 1 : 0;
}
