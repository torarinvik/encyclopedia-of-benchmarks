#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define SCH_MAX_N 6
#define SCH_MAX_M 4
#define SCH_MAX_CALLS (SCH_MAX_N + 1)
#define SCH_MAX_INPUT 122

typedef struct {
    int calls;
    int unit_forces;
    int random_guesses;
    int max_depth;
} sch_stats;

static int sch_prefix_size(int clauses) {
    int bits = 0;
    while (clauses > 0) { ++bits; clauses >>= 1; }
    return bits + 1;
}

static int sch_ppz(int n, int m, int formula[SCH_MAX_M][SCH_MAX_N],
                   int lengths[SCH_MAX_M], const int fixed[SCH_MAX_N],
                   const int permutation[SCH_MAX_N], const int bits[SCH_MAX_N],
                   int local[SCH_MAX_N], sch_stats *stats) {
    int active[SCH_MAX_N], active_count = 0;
    for (int item = 0; item < n; ++item) local[item] = -1;
    for (int position = 0; position < n; ++position) {
        const int variable = permutation[position] - 1;
        if (fixed[variable] < 0) active[active_count++] = variable;
    }

    int work[SCH_MAX_M][SCH_MAX_N] = {{0}};
    int work_lengths[SCH_MAX_M] = {0};
    for (int clause = 0; clause < m; ++clause) {
        work_lengths[clause] = lengths[clause];
        for (int item = 0; item < lengths[clause]; ++item)
            work[clause][item] = formula[clause][item];
    }

    for (int offset = 0; offset < active_count; ++offset) {
        const int variable = active[offset];
        int positive_unit = 0, negative_unit = 0;
        for (int clause = 0; clause < m; ++clause) {
            if (work_lengths[clause] != 1) continue;
            if (work[clause][0] == variable + 1) positive_unit = 1;
            if (work[clause][0] == -(variable + 1)) negative_unit = 1;
        }
        int value;
        if (positive_unit) { value = 1; ++stats->unit_forces; }
        else if (negative_unit) { value = 0; ++stats->unit_forces; }
        else { value = bits[offset]; ++stats->random_guesses; }
        local[variable] = value;

        int next[SCH_MAX_M][SCH_MAX_N] = {{0}};
        int next_lengths[SCH_MAX_M] = {0};
        int next_m = 0;
        for (int clause = 0; clause < m; ++clause) {
            int satisfied = 0, out_length = 0;
            for (int item = 0; item < work_lengths[clause]; ++item) {
                const int literal = work[clause][item];
                if (abs(literal) - 1 != variable) {
                    next[next_m][out_length++] = literal;
                } else {
                    const int literal_true = (literal > 0) == (value != 0);
                    if (literal_true) { satisfied = 1; break; }
                }
            }
            if (!satisfied) next_lengths[next_m++] = out_length;
        }
        for (int clause = 0; clause < next_m; ++clause) {
            work_lengths[clause] = next_lengths[clause];
            for (int item = 0; item < next_lengths[clause]; ++item)
                work[clause][item] = next[clause][item];
        }
        m = next_m;
    }
    for (int clause = 0; clause < m; ++clause)
        if (work_lengths[clause] == 0) return 0;
    return 1;
}

static void sch_put_i64(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[8 * word + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t schuler_randomized_general_cnf_sat(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > SCH_MAX_INPUT) return -1;
    const int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > SCH_MAX_N || m0 < 1 || m0 > SCH_MAX_M) return -1;
    const int n = (int)n0, m0i = (int)m0;
    int formula[SCH_MAX_M][SCH_MAX_N] = {{0}};
    int lengths[SCH_MAX_M] = {0};
    size_t position = 2;
    for (int clause = 0; clause < m0i; ++clause) {
        if (position >= length) return -1;
        const int64_t count0 = input[position++];
        if (count0 < 1 || count0 > n || position + (size_t)count0 > length) return -1;
        int seen[SCH_MAX_N] = {0};
        lengths[clause] = (int)count0;
        for (int item = 0; item < lengths[clause]; ++item) {
            const int64_t literal0 = input[position++];
            if (literal0 == 0 || literal0 < -n || literal0 > n) return -1;
            const int variable = (int)(literal0 < 0 ? -literal0 : literal0) - 1;
            if (seen[variable]) return -1;
            seen[variable] = 1;
            formula[clause][item] = (int)literal0;
        }
    }

    int permutation[SCH_MAX_CALLS][SCH_MAX_N] = {{0}};
    int random_bits[SCH_MAX_CALLS][SCH_MAX_N] = {{0}};
    int choices[SCH_MAX_CALLS] = {0};
    for (int call = 0; call <= n; ++call) {
        int seen[SCH_MAX_N] = {0};
        for (int item = 0; item < n; ++item) {
            if (position >= length) return -1;
            const int64_t value = input[position++];
            if (value < 1 || value > n || seen[(int)value - 1]) return -1;
            seen[(int)value - 1] = 1;
            permutation[call][item] = (int)value;
        }
        for (int item = 0; item < n; ++item) {
            if (position >= length || (input[position] != 0 && input[position] != 1)) return -1;
            random_bits[call][item] = (int)input[position++];
        }
        if (position >= length) return -1;
        const int64_t choice = input[position++];
        if (choice < 0 || choice >= m0) return -1;
        choices[call] = (int)choice;
    }
    if (position != length) return -1;

    int fixed[SCH_MAX_N];
    for (int variable = 0; variable < n; ++variable) fixed[variable] = -1;
    int current[SCH_MAX_M][SCH_MAX_N] = {{0}};
    int current_lengths[SCH_MAX_M] = {0};
    int current_m = m0i;
    for (int clause = 0; clause < current_m; ++clause) {
        current_lengths[clause] = lengths[clause];
        for (int item = 0; item < lengths[clause]; ++item)
            current[clause][item] = formula[clause][item];
    }
    sch_stats stats = {0, 0, 0, 0};
    int found = 0, mask = 0, depth = 0;
    while (1) {
        ++stats.calls;
        if (depth > stats.max_depth) stats.max_depth = depth;
        if (current_m == 0) {
            found = 1;
            for (int variable = 0; variable < n; ++variable)
                if (fixed[variable] == 1) mask |= 1 << variable;
            break;
        }
        const int k = sch_prefix_size(current_m);
        int shortened[SCH_MAX_M][SCH_MAX_N] = {{0}};
        int short_lengths[SCH_MAX_M] = {0};
        for (int clause = 0; clause < current_m; ++clause) {
            short_lengths[clause] = current_lengths[clause] < k ? current_lengths[clause] : k;
            for (int item = 0; item < short_lengths[clause]; ++item)
                shortened[clause][item] = current[clause][item];
        }
        int local[SCH_MAX_N] = {-1, -1, -1, -1, -1, -1};
        const int ppz_success = sch_ppz(n, current_m, shortened, short_lengths, fixed,
                                        permutation[depth], random_bits[depth], local, &stats);
        if (ppz_success) {
            found = 1;
            for (int variable = 0; variable < n; ++variable) {
                const int value = fixed[variable] >= 0 ? fixed[variable] : local[variable];
                if (value == 1) mask |= 1 << variable;
            }
            break;
        }
        int eligible[SCH_MAX_M], eligible_count = 0;
        for (int clause = 0; clause < current_m; ++clause)
            if (short_lengths[clause] == k) eligible[eligible_count++] = clause;
        if (eligible_count == 0) break;
        if (choices[depth] >= eligible_count) return -1;
        const int selected = eligible[choices[depth]];
        int next_fixed[SCH_MAX_N];
        for (int variable = 0; variable < n; ++variable) next_fixed[variable] = fixed[variable];
        for (int item = 0; item < k; ++item) {
            const int literal = shortened[selected][item];
            next_fixed[abs(literal) - 1] = literal > 0 ? 0 : 1;
        }
        int next[SCH_MAX_M][SCH_MAX_N] = {{0}};
        int next_lengths[SCH_MAX_M] = {0};
        int next_m = 0;
        for (int clause = 0; clause < current_m; ++clause) {
            int satisfied = 0, out_length = 0;
            for (int item = 0; item < current_lengths[clause]; ++item) {
                const int literal = current[clause][item];
                const int value = next_fixed[abs(literal) - 1];
                if (value < 0) next[next_m][out_length++] = literal;
                else if ((literal > 0) == (value != 0)) { satisfied = 1; break; }
            }
            if (!satisfied) next_lengths[next_m++] = out_length;
        }
        for (int clause = 0; clause < next_m; ++clause) {
            current_lengths[clause] = next_lengths[clause];
            for (int item = 0; item < next_lengths[clause]; ++item)
                current[clause][item] = next[clause][item];
        }
        current_m = next_m;
        for (int variable = 0; variable < n; ++variable) fixed[variable] = next_fixed[variable];
        ++depth;
        if (depth > n) return -1;
    }
    if (!found) mask = 0;
    int64_t staged[6] = {found, mask, stats.calls, stats.unit_forces,
                         stats.random_guesses, stats.max_depth};
    if (output == NULL || capacity < 48) return -2;
    for (size_t word = 0; word < 6; ++word) sch_put_i64(output, word, staged[word]);
    return 48;
}
