#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_VARS = 5, MAX_CLAUSES = 6, MAX_LITS = 30;
struct Formula { int count{}; int length[MAX_CLAUSES]{}; int literal[MAX_LITS]{}; };
struct Stats { std::int64_t calls{}, tests{}, branches{}, max_depth{}; };
void put_i64(std::uint8_t *out, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
Formula shorten(const Formula &f, int k) {
    Formula d{}; d.count = f.count;
    for (int c = 0; c < f.count; ++c) {
        d.length[c] = f.length[c] < k ? f.length[c] : k;
        for (int j = 0; j < d.length[c]; ++j) d.literal[c * MAX_VARS + j] = f.literal[c * MAX_VARS + j];
    }
    return d;
}
bool exact_sat(const Formula &f, int n, std::uint32_t fixed_mask, std::uint32_t fixed_values, std::uint32_t &model) {
    for (std::uint32_t code = 0; code < (1u << n); ++code) {
        std::uint32_t candidate = 0;
        for (int v = 0; v < n; ++v) if ((code >> (n - v - 1)) & 1u) candidate |= 1u << v;
        if (((candidate ^ fixed_values) & fixed_mask) != 0) continue;
        bool all = true;
        for (int c = 0; c < f.count && all; ++c) {
            bool one = false;
            for (int j = 0; j < f.length[c]; ++j) {
                const int lit = f.literal[c * MAX_VARS + j];
                const bool value = ((candidate >> (lit > 0 ? lit - 1 : -lit - 1)) & 1u) != 0;
                if ((lit > 0 && value) || (lit < 0 && !value)) { one = true; break; }
            }
            all = one;
        }
        if (all) { model = candidate; return true; }
    }
    return false;
}
bool solve(Formula f, int n, int k, std::uint32_t fixed_mask, std::uint32_t fixed_values,
           int depth, Stats &stats, std::uint32_t &model) {
    ++stats.calls; if (depth > stats.max_depth) stats.max_depth = depth;
    const Formula d = shorten(f, k); ++stats.tests;
    if (exact_sat(d, n, fixed_mask, fixed_values, model)) return true;
    for (int branch = 0; branch < f.count; ++branch) {
        if (d.length[branch] == 0) continue;
        ++stats.branches;
        auto next_mask = fixed_mask, next_values = fixed_values;
        bool conflict = false;
        for (int j = 0; j < d.length[branch]; ++j) {
            const int lit = d.literal[branch * MAX_VARS + j];
            const auto bit = 1u << (lit > 0 ? lit - 1 : -lit - 1);
            const std::uint32_t value = lit < 0 ? bit : 0u;
            if ((next_mask & bit) && ((next_values & bit) != value)) { conflict = true; break; }
            next_mask |= bit; next_values = (next_values & ~bit) | value;
        }
        if (conflict || next_mask == fixed_mask) continue;
        Formula child{};
        const auto newly_fixed = next_mask & ~fixed_mask;
        for (int c = 0; c < f.count; ++c) {
            const Formula &source = c < branch ? d : f;
            bool satisfied = false; int kept = 0;
            for (int j = 0; j < source.length[c]; ++j) {
                const int lit = source.literal[c * MAX_VARS + j];
                const auto bit = 1u << (lit > 0 ? lit - 1 : -lit - 1);
                if (newly_fixed & bit) {
                    const bool truth = (next_values & bit) != 0;
                    if ((lit > 0 && truth) || (lit < 0 && !truth)) { satisfied = true; break; }
                } else child.literal[child.count * MAX_VARS + kept++] = lit;
            }
            if (!satisfied) child.length[child.count++] = kept;
        }
        if (solve(child, n, k, next_mask, next_values, depth + 1, stats, model)) return true;
    }
    return false;
}
}

extern "C" std::int64_t procedure_s_general_cnf_sat(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 39) return -1;
    const auto n0 = input[0], m0 = input[1], k0 = input[2];
    if (n0 < 1 || n0 > MAX_VARS || m0 < 0 || m0 > MAX_CLAUSES || k0 < 1 || k0 > n0) return -1;
    const int n = static_cast<int>(n0), m = static_cast<int>(m0), k = static_cast<int>(k0);
    Formula f{}; f.count = m; std::size_t at = 3;
    for (int c = 0; c < m; ++c) {
        if (at >= length || input[at] < 1 || input[at] > n) return -1;
        const int count = static_cast<int>(input[at++]); if (at + static_cast<std::size_t>(count) > length) return -1;
        std::uint32_t seen = 0; f.length[c] = count;
        for (int j = 0; j < count; ++j) {
            const auto value = input[at++]; if (value == 0 || value > n || value < -n) return -1;
            const int lit = static_cast<int>(value); const auto bit = 1u << (lit > 0 ? lit - 1 : -lit - 1);
            if (seen & bit) return -1; seen |= bit; f.literal[c * MAX_VARS + j] = lit;
        }
    }
    if (at != length) return -1;
    Stats stats{}; std::uint32_t model = 0;
    const bool sat = solve(f, n, k, 0, 0, 0, stats, model);
    if (output == nullptr || capacity < 48) return -2;
    put_i64(output, 0, sat ? 1 : 0); put_i64(output, 1, sat ? model : 0);
    put_i64(output, 2, stats.calls); put_i64(output, 3, stats.tests);
    put_i64(output, 4, stats.branches); put_i64(output, 5, stats.max_depth);
    return 48;
}
