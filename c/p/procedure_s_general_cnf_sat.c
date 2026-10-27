#include <stddef.h>
#include <stdint.h>

#define MAX_VARS 5
#define MAX_CLAUSES 6
#define MAX_LITS 30

typedef struct { int count; int length[MAX_CLAUSES]; int literal[MAX_LITS]; } Formula;
typedef struct { int64_t calls, tests, branches, max_depth; } Stats;

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

static void shorten(const Formula *formula, int k, Formula *prefix) {
    prefix->count = formula->count;
    for (int c = 0; c < formula->count; ++c) {
        const int take = formula->length[c] < k ? formula->length[c] : k;
        prefix->length[c] = take;
        for (int j = 0; j < take; ++j) prefix->literal[c * MAX_VARS + j] = formula->literal[c * MAX_VARS + j];
    }
}

static int exact_sat(const Formula *formula, int variables, uint32_t fixed_mask,
                     uint32_t fixed_values, uint32_t *model) {
    const uint32_t limit = 1u << variables;
    for (uint32_t code = 0; code < limit; ++code) {
        uint32_t candidate = 0;
        for (int variable = 0; variable < variables; ++variable) {
            const uint32_t bit = (code >> (variables - variable - 1)) & 1u;
            if (bit) candidate |= 1u << variable;
        }
        if (((candidate ^ fixed_values) & fixed_mask) != 0) continue;
        int formula_sat = 1;
        for (int c = 0; c < formula->count && formula_sat; ++c) {
            int clause_sat = 0;
            for (int j = 0; j < formula->length[c]; ++j) {
                const int literal = formula->literal[c * MAX_VARS + j];
                const int truth = (candidate >> (literal > 0 ? literal - 1 : -literal - 1)) & 1u;
                if ((literal > 0 && truth) || (literal < 0 && !truth)) { clause_sat = 1; break; }
            }
            if (!clause_sat) formula_sat = 0;
        }
        if (formula_sat) { *model = candidate; return 1; }
    }
    return 0;
}

static int solve(Formula formula, int variables, int k, uint32_t fixed_mask,
                 uint32_t fixed_values, int depth, Stats *stats, uint32_t *model) {
    ++stats->calls;
    if (depth > stats->max_depth) stats->max_depth = depth;
    Formula prefixes = {0};
    shorten(&formula, k, &prefixes);
    ++stats->tests;
    if (exact_sat(&prefixes, variables, fixed_mask, fixed_values, model)) return 1;
    for (int branch = 0; branch < formula.count; ++branch) {
        const int branch_length = prefixes.length[branch];
        if (branch_length == 0) continue;
        ++stats->branches;
        uint32_t next_mask = fixed_mask, next_values = fixed_values;
        int conflict = 0;
        for (int j = 0; j < branch_length; ++j) {
            const int literal = prefixes.literal[branch * MAX_VARS + j];
            const uint32_t bit = 1u << (literal > 0 ? literal - 1 : -literal - 1);
            const uint32_t value = literal < 0 ? bit : 0u;
            if ((next_mask & bit) && ((next_values & bit) != value)) { conflict = 1; break; }
            next_mask |= bit;
            next_values = (next_values & ~bit) | value;
        }
        if (conflict || next_mask == fixed_mask) continue;
        Formula child = {0};
        const uint32_t newly_fixed = next_mask & ~fixed_mask;
        for (int c = 0; c < formula.count; ++c) {
            const Formula *source = c < branch ? &prefixes : &formula;
            int kept = 0, satisfied = 0;
            for (int j = 0; j < source->length[c]; ++j) {
                const int literal = source->literal[c * MAX_VARS + j];
                const uint32_t bit = 1u << (literal > 0 ? literal - 1 : -literal - 1);
                if (newly_fixed & bit) {
                    const int truth = (next_values & bit) != 0;
                    if ((literal > 0 && truth) || (literal < 0 && !truth)) { satisfied = 1; break; }
                } else {
                    child.literal[child.count * MAX_VARS + kept++] = literal;
                }
            }
            if (!satisfied) child.length[child.count++] = kept;
        }
        if (solve(child, variables, k, next_mask, next_values, depth + 1, stats, model)) return 1;
    }
    return 0;
}

int64_t procedure_s_general_cnf_sat(const int64_t *input, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 39) return -1;
    const int64_t variables0 = input[0], clauses0 = input[1], k0 = input[2];
    if (variables0 < 1 || variables0 > MAX_VARS || clauses0 < 0 || clauses0 > MAX_CLAUSES
        || k0 < 1 || k0 > variables0) return -1;
    const int variables = (int)variables0, clause_count = (int)clauses0, k = (int)k0;
    Formula formula = {0}; formula.count = clause_count;
    size_t at = 3;
    for (int c = 0; c < clause_count; ++c) {
        if (at >= length || input[at] < 1 || input[at] > variables) return -1;
        const int count = (int)input[at++];
        if (at + (size_t)count > length) return -1;
        uint32_t seen = 0;
        formula.length[c] = count;
        for (int j = 0; j < count; ++j) {
            const int64_t value = input[at++];
            if (value == 0 || value > variables || value < -variables) return -1;
            const int literal = (int)value;
            const uint32_t bit = 1u << (literal > 0 ? literal - 1 : -literal - 1);
            if (seen & bit) return -1;
            seen |= bit;
            formula.literal[c * MAX_VARS + j] = literal;
        }
    }
    if (at != length) return -1;
    Stats stats = {0};
    uint32_t model = 0;
    const int satisfiable = solve(formula, variables, k, 0, 0, 0, &stats, &model);
    const size_t bytes = 48;
    if (output == NULL || output_capacity < bytes) return -2;
    put_i64(output, 0, satisfiable ? 1 : 0);
    put_i64(output, 1, satisfiable ? (int64_t)model : 0);
    put_i64(output, 2, stats.calls);
    put_i64(output, 3, stats.tests);
    put_i64(output, 4, stats.branches);
    put_i64(output, 5, stats.max_depth);
    return (int64_t)bytes;
}
