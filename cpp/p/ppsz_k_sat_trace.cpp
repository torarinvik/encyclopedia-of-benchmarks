#include <cstddef>
#include <cstdint>

namespace {
constexpr int MaxN = 8, MaxClauses = 12, MaxInput = 54, MaxOutput = 72;
void put(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[offset + i] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
int fixed_mask(int mask, const int assigned[MaxN], int n) {
    for (int i = 0; i < n; ++i) if (assigned[i] >= 0) { if (assigned[i]) mask |= 1 << i; else mask &= ~(1 << i); }
    return mask;
}
bool clause_true(const int clause[3], int mask) {
    for (int j = 0; j < 3; ++j) {
        const int literal = clause[j];
        const int bit = (mask >> ((literal < 0 ? -literal : literal) - 1)) & 1;
        if ((literal > 0 && bit) || (literal < 0 && !bit)) return true;
    }
    return false;
}
bool selected_true(const int clauses[MaxClauses][3], int m, int subset, int mask) {
    for (int i = 0; i < m; ++i) if ((subset & (1 << i)) && !clause_true(clauses[i], mask)) return false;
    return true;
}
int popcount(int value) { int count = 0; while (value) { count += value & 1; value >>= 1; } return count; }
bool current_sat(int n, int m, const int clauses[MaxClauses][3], const int assigned[MaxN]) {
    for (int mask = 0; mask < (1 << n); ++mask)
        if (selected_true(clauses, m, (1 << m) - 1, fixed_mask(mask, assigned, n))) return true;
    return false;
}
bool find_force(int n, int m, const int clauses[MaxClauses][3], const int assigned[MaxN], int &variable, int &value) {
    if (!current_sat(n, m, clauses, assigned)) return false;
    int threshold = 0; while ((1 << (threshold + 1)) <= n) ++threshold;
    int implied[MaxN]; for (int i = 0; i < MaxN; ++i) implied[i] = -1;
    for (int subset = 1; subset < (1 << m); ++subset) {
        if (popcount(subset) > threshold) continue;
        int zero[MaxN] = {}, one[MaxN] = {};
        for (int mask = 0; mask < (1 << n); ++mask) {
            const int full = fixed_mask(mask, assigned, n);
            if (selected_true(clauses, m, subset, full)) for (int x = 0; x < n; ++x)
                if (assigned[x] < 0) { if ((full >> x) & 1) one[x] = 1; else zero[x] = 1; }
        }
        for (int x = 0; x < n; ++x) if (assigned[x] < 0 && zero[x] != one[x] && implied[x] < 0) implied[x] = one[x] ? 1 : 0;
    }
    for (int x = 0; x < n; ++x) if (implied[x] >= 0) { variable = x; value = implied[x]; return true; }
    return false;
}
}

extern "C" std::int64_t ppsz_k_sat_trace(const std::int64_t *v, std::size_t length,
                                          std::uint8_t *output, std::size_t capacity) {
    if (!v || length < 2 || length > MaxInput || v[0] < 3 || v[0] > MaxN || v[1] < 0 || v[1] > MaxClauses) return -1;
    const int n = static_cast<int>(v[0]), m = static_cast<int>(v[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m + 2 * n)) return -1;
    int clauses[MaxClauses][3]{};
    for (int i = 0; i < m; ++i) {
        bool seen[MaxN]{};
        for (int j = 0; j < 3; ++j) {
            const std::int64_t literal = v[2 + 3 * i + j]; if (literal == 0 || literal < -n || literal > n) return -1;
            const int x = static_cast<int>(literal < 0 ? -literal : literal) - 1; if (seen[x]) return -1; seen[x] = true; clauses[i][j] = static_cast<int>(literal);
        }
    }
    const int start = 2 + 3 * m; int order[MaxN], beta[MaxN], assigned[MaxN], seen[MaxN]{};
    for (int i = 0; i < MaxN; ++i) assigned[i] = -1;
    for (int i = 0; i < n; ++i) { const auto x = v[start + i]; if (x < 0 || x >= n || seen[x]) return -1; order[i] = static_cast<int>(x); seen[x] = 1; }
    for (int i = 0; i < n; ++i) { const auto b = v[start + n + i]; if (b != 0 && b != 1) return -1; beta[i] = static_cast<int>(b); }
    for (int step = 0; step < n; ++step) {
        int forced, bit; while (find_force(n, m, clauses, assigned, forced, bit)) assigned[forced] = bit;
        const int x = order[step]; if (assigned[x] < 0) assigned[x] = beta[x];
    }
    int mask = 0; for (int i = 0; i < n; ++i) if (assigned[i]) mask |= 1 << i;
    const std::int64_t verdict = selected_true(clauses, m, (1 << m) - 1, mask) ? 1 : 0;
    const std::size_t bytes = 8 * static_cast<std::size_t>(n + 1); if (!output || capacity < bytes) return -2;
    std::uint8_t staged[MaxOutput]{}; put(staged, 0, verdict);
    for (int i = 0; i < n; ++i) put(staged, 8 * static_cast<std::size_t>(i + 1), assigned[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i]; return static_cast<std::int64_t>(bytes);
}
