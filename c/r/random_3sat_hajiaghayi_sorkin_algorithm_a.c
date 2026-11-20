#include <stddef.h>
#include <stdint.h>

enum { MAX_VARS = 12, MAX_CLAUSES = 32, MAX_INPUT = 98, MAX_OUTPUT = 104 };

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[at + byte] = (uint8_t)(bits & 255);
        bits >>= 8;
    }
}

static int reduce_by_literal(int clauses[MAX_CLAUSES][3], int lengths[MAX_CLAUSES],
                             int active[MAX_CLAUSES], int count, int literal) {
    for (int clause = 0; clause < count; ++clause) {
        if (!active[clause]) continue;
        int satisfied = 0;
        for (int at = 0; at < lengths[clause]; ++at) {
            if (clauses[clause][at] == literal) satisfied = 1;
        }
        if (satisfied) {
            active[clause] = 0;
            continue;
        }
        int write = 0;
        for (int at = 0; at < lengths[clause]; ++at) {
            if (clauses[clause][at] != -literal) {
                clauses[clause][write++] = clauses[clause][at];
            }
        }
        lengths[clause] = write;
        if (write == 0) return 0;
    }
    return 1;
}

static int choose_free_literal(int n, int clauses[MAX_CLAUSES][3],
                               int lengths[MAX_CLAUSES], int active[MAX_CLAUSES],
                               const int assigned[MAX_VARS]) {
    int positive[MAX_VARS] = {0};
    int negative[MAX_VARS] = {0};
    for (int clause = 0; clause < MAX_CLAUSES; ++clause) {
        if (!active[clause]) continue;
        for (int at = 0; at < lengths[clause]; ++at) {
            int literal = clauses[clause][at];
            int variable = (literal > 0 ? literal : -literal) - 1;
            if (literal > 0) ++positive[variable];
            else ++negative[variable];
        }
    }

    int variable = -1;
    for (int v = 0; v < n; ++v) {
        if (assigned[v] == 0 && (positive[v] == 0 || negative[v] == 0)) {
            variable = v;
            break;
        }
    }
    if (variable < 0) {
        int best_discrepancy = -1;
        int best_total = -1;
        for (int v = 0; v < n; ++v) {
            if (assigned[v] != 0) continue;
            int difference = positive[v] - negative[v];
            if (difference < 0) difference = -difference;
            int total = positive[v] + negative[v];
            if (difference > best_discrepancy ||
                (difference == best_discrepancy && total > best_total)) {
                best_discrepancy = difference;
                best_total = total;
                variable = v;
            }
        }
    }
    if (variable < 0) return 0;
    return positive[variable] < negative[variable] ? variable + 1 : -(variable + 1);
}

int64_t random_3sat_hajiaghayi_sorkin_algorithm_a(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT || input[0] < 3 ||
        input[0] > MAX_VARS || input[1] < 0 || input[1] > MAX_CLAUSES) return -1;
    int n = (int)input[0];
    int m = (int)input[1];
    if (length != (size_t)(2 + 3 * m)) return -1;

    int clauses[MAX_CLAUSES][3] = {{0}};
    int lengths[MAX_CLAUSES] = {0};
    int active[MAX_CLAUSES] = {0};
    for (int clause = 0; clause < m; ++clause) {
        int seen[MAX_VARS] = {0};
        for (int at = 0; at < 3; ++at) {
            int64_t raw = input[2 + 3 * clause + at];
            if (raw == 0 || raw < -n || raw > n) return -1;
            int variable = (int)(raw > 0 ? raw : -raw) - 1;
            if (seen[variable]) return -1;
            seen[variable] = 1;
            clauses[clause][at] = (int)raw;
        }
        lengths[clause] = 3;
        active[clause] = 1;
    }

    int assigned[MAX_VARS] = {0};
    int assigned_count = 0;
    int failed = 0;
    while (assigned_count < n && !failed) {
        int chosen = choose_free_literal(n, clauses, lengths, active, assigned);
        if (chosen == 0) {
            failed = 1;
            break;
        }
        int variable = (chosen > 0 ? chosen : -chosen) - 1;
        assigned[variable] = chosen > 0 ? 1 : -1;
        ++assigned_count;
        if (!reduce_by_literal(clauses, lengths, active, m, chosen)) {
            failed = 1;
            break;
        }

        while (!failed) {
            int unit = 0;
            for (int clause = 0; clause < m; ++clause) {
                if (active[clause] && lengths[clause] == 1) {
                    unit = clauses[clause][0];
                    break;
                }
            }
            if (unit == 0) break;
            variable = (unit > 0 ? unit : -unit) - 1;
            assigned[variable] = unit > 0 ? 1 : -1;
            ++assigned_count;
            if (!reduce_by_literal(clauses, lengths, active, m, unit)) failed = 1;
        }
    }

    int64_t result[ MAX_VARS + 1 ] = {0};
    result[0] = failed ? 0 : 1;
    for (int v = 0; v < n; ++v) result[v + 1] = assigned[v];
    size_t bytes = 8 * (size_t)(n + 1);
    if (!output || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    for (int word = 0; word <= n; ++word) put_i64(staged, 8 * (size_t)word, result[word]);
    for (size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)bytes;
}
