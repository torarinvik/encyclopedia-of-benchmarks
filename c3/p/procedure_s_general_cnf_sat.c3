module procedure_s_general_cnf_sat;

const int MAX_VARS = 5;
const int MAX_CLAUSES = 6;
const int MAX_LITS = 30;

struct Formula { int count; int[MAX_CLAUSES] lengths; int[MAX_LITS] literals; }
struct Stats { long calls; long tests; long branches; long max_depth; }

fn void put_i64(uint8* out, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[word * 8 + b] = (uint8)(bits >> (8 * b));
}
fn Formula shorten(Formula f, int k) {
    Formula d = {}; d.count = f.count;
    for (int c = 0; c < f.count; c++) {
        d.lengths[c] = f.lengths[c] < k ? f.lengths[c] : k;
        for (int j = 0; j < d.lengths[c]; j++) d.literals[c * MAX_VARS + j] = f.literals[c * MAX_VARS + j];
    }
    return d;
}
fn bool exact_sat(Formula f, int n, uint fixed_mask, uint fixed_values, uint* model) {
    uint limit = 1u << n;
    for (uint code = 0; code < limit; code++) {
        uint candidate = 0;
        for (int v = 0; v < n; v++) if ((code >> (n - v - 1)) & 1u) candidate |= 1u << v;
        if (((candidate ^ fixed_values) & fixed_mask) != 0) continue;
        bool all = true;
        for (int c = 0; c < f.count && all; c++) {
            bool one = false;
            for (int j = 0; j < f.lengths[c]; j++) {
                int lit = f.literals[c * MAX_VARS + j];
                bool truth = (candidate >> (lit > 0 ? lit - 1 : -lit - 1)) & 1u;
                if ((lit > 0 && truth) || (lit < 0 && !truth)) { one = true; break; }
            }
            all = one;
        }
        if (all) { *model = candidate; return true; }
    }
    return false;
}
fn bool solve(Formula f, int n, int k, uint fixed_mask, uint fixed_values,
              int depth, Stats* stats, uint* model) {
    stats.calls++; if (depth > stats.max_depth) stats.max_depth = depth;
    Formula d = shorten(f, k); stats.tests++;
    if (exact_sat(d, n, fixed_mask, fixed_values, model)) return true;
    for (int branch = 0; branch < f.count; branch++) {
        if (d.lengths[branch] == 0) continue;
        stats.branches++;
        uint next_mask = fixed_mask, next_values = fixed_values;
        bool conflict = false;
        for (int j = 0; j < d.lengths[branch]; j++) {
            int lit = d.literals[branch * MAX_VARS + j];
            uint bit = 1u << (lit > 0 ? lit - 1 : -lit - 1);
            uint value = lit < 0 ? bit : 0u;
            if ((next_mask & bit) && ((next_values & bit) != value)) { conflict = true; break; }
            next_mask |= bit; next_values = (next_values & ~bit) | value;
        }
        if (conflict || next_mask == fixed_mask) continue;
        Formula child = {};
        uint newly_fixed = next_mask & ~fixed_mask;
        for (int c = 0; c < f.count; c++) {
            Formula source = c < branch ? d : f;
            bool satisfied = false; int kept = 0;
            for (int j = 0; j < source.lengths[c]; j++) {
                int lit = source.literals[c * MAX_VARS + j];
                uint bit = 1u << (lit > 0 ? lit - 1 : -lit - 1);
                if (newly_fixed & bit) {
                    bool truth = (next_values & bit) != 0;
                    if ((lit > 0 && truth) || (lit < 0 && !truth)) { satisfied = true; break; }
                } else child.literals[child.count * MAX_VARS + kept++] = lit;
            }
            if (!satisfied) child.lengths[child.count++] = kept;
        }
        if (solve(child, n, k, next_mask, next_values, depth + 1, stats, model)) return true;
    }
    return false;
}

fn long procedure_s_general_cnf_sat(long* input, usz length, uint8* output, usz output_capacity)
    @export("procedure_s_general_cnf_sat") {
    if (input == null || length < 3 || length > 39) return -1;
    long n0 = input[0], m0 = input[1], k0 = input[2];
    if (n0 < 1 || n0 > MAX_VARS || m0 < 0 || m0 > MAX_CLAUSES || k0 < 1 || k0 > n0) return -1;
    int n = (int)n0, m = (int)m0, k = (int)k0;
    Formula f = {}; f.count = m; usz at = 3;
    for (int c = 0; c < m; c++) {
        if (at >= length || input[at] < 1 || input[at] > n0) return -1;
        int count = (int)input[at++]; if (at + (usz)count > length) return -1;
        uint seen = 0; f.lengths[c] = count;
        for (int j = 0; j < count; j++) {
            long value = input[at++]; if (value == 0 || value > n0 || value < -n0) return -1;
            int lit = (int)value; uint bit = 1u << (lit > 0 ? lit - 1 : -lit - 1);
            if (seen & bit) return -1;
            seen |= bit; f.literals[c * MAX_VARS + j] = lit;
        }
    }
    if (at != length) return -1;
    Stats stats = {}; uint model = 0;
    bool sat = solve(f, n, k, 0, 0, 0, &stats, &model);
    if (output == null || output_capacity < 48) return -2;
    put_i64(output, 0, sat ? 1 : 0); put_i64(output, 1, sat ? (long)model : 0);
    put_i64(output, 2, stats.calls); put_i64(output, 3, stats.tests);
    put_i64(output, 4, stats.branches); put_i64(output, 5, stats.max_depth);
    return 48;
}
