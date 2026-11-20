#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int N = 8, M = 24, WORDS = 44, OUT_BYTES = 352;

struct Formula {
    std::array<std::array<int, 3>, M> literals{};
    std::array<int, M> lengths{};
    std::array<bool, M> active{};
};
struct Event { int literal, kind, i, j; };

void write_word(std::uint8_t *out, std::size_t offset, std::int64_t word) {
    auto bits = static_cast<std::uint64_t>(word);
    for (std::size_t b = 0; b < 8; ++b) {
        out[offset + b] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}

bool simplify(Formula &f, int m, std::array<int, N> &values, int literal) {
    const int variable = (literal > 0 ? literal : -literal) - 1;
    const int value = literal > 0 ? 1 : -1;
    if (values[variable] != 0 && values[variable] != value) return false;
    values[variable] = value;
    for (int c = 0; c < m; ++c) {
        if (!f.active[c]) continue;
        bool satisfied = false;
        for (int j = 0; j < f.lengths[c]; ++j)
            if (f.literals[c][j] == literal) satisfied = true;
        if (satisfied) { f.active[c] = false; continue; }
        int kept = 0;
        for (int j = 0; j < f.lengths[c]; ++j)
            if (f.literals[c][j] != -literal) f.literals[c][kept++] = f.literals[c][j];
        f.lengths[c] = kept;
        if (kept == 0) return false;
    }
    return true;
}

bool propagate(Formula &f, int m, std::array<int, N> &values,
               std::array<Event, N> *events, int *event_count) {
    for (;;) {
        int unit = 0;
        for (int c = 0; c < m; ++c)
            if (f.active[c] && f.lengths[c] == 1) { unit = f.literals[c][0]; break; }
        if (unit == 0) return true;
        if (events != nullptr) (*events)[(*event_count)++] = {unit, 1, -1, -1};
        if (!simplify(f, m, values, unit)) return false;
    }
}

void degrees(const Formula &f, int m, int n, std::array<int, N> &positive,
             std::array<int, N> &negative) {
    positive.fill(0); negative.fill(0);
    for (int c = 0; c < m; ++c) if (f.active[c])
        for (int j = 0; j < f.lengths[c]; ++j) {
            int x = f.literals[c][j];
            if (x > 0) ++positive[x - 1]; else ++negative[-x - 1];
        }
    (void)n;
}

int member(const Formula &f, int m, int n, const std::array<int, N> &values,
           int bi, int bj) {
    std::array<int, N> pos{}, neg{};
    degrees(f, m, n, pos, neg);
    for (int v = 0; v < n; ++v) {
        if (values[v] != 0) continue;
        const int p = pos[v] < 10 ? pos[v] : 10;
        const int q = neg[v] < 10 ? neg[v] : 10;
        if (p == bi && q == bj) return v + 1;
        if (q == bi && p == bj) return -(v + 1);
    }
    return 0;
}

void flows(const Formula &f, int m, int n, int &s2, int &s3, int &den) {
    std::array<int, N> p2{}, n2{}, p3{}, n3{};
    int clauses2 = 0;
    for (int c = 0; c < m; ++c) if (f.active[c]) {
        if (f.lengths[c] == 2) ++clauses2;
        auto *p = f.lengths[c] == 2 ? &p2 : (f.lengths[c] == 3 ? &p3 : nullptr);
        auto *q = f.lengths[c] == 2 ? &n2 : (f.lengths[c] == 3 ? &n3 : nullptr);
        if (p == nullptr) continue;
        for (int j = 0; j < f.lengths[c]; ++j) {
            int x = f.literals[c][j];
            if (x > 0) ++(*p)[x - 1]; else ++(*q)[-x - 1];
        }
    }
    s2 = 0; s3 = 0;
    for (int c = 0; c < m; ++c) if (f.active[c] && f.lengths[c] == 2)
        for (int j = 0; j < 2; ++j) {
            const int x = -f.literals[c][j];
            s2 += x > 0 ? p2[x - 1] : n2[-x - 1];
            s3 += x > 0 ? p3[x - 1] : n3[-x - 1];
        }
    den = clauses2 == 0 ? 1 : clauses2 * 2;
    (void)n;
}

bool choose(const Formula &f, int m, int n, const std::array<int, N> &values,
            int &best_i, int &best_j) {
    int old2, old3, oldden;
    flows(f, m, n, old2, old3, oldden);
    bool found = false;
    std::int64_t best_num = 0, best_den = 1;
    for (int i = 0; i <= 10; ++i) for (int j = 0; j <= 10; ++j) {
        const int literal = member(f, m, n, values, i, j);
        if (literal == 0) continue;
        Formula trial = f;
        auto trial_values = values;
        if (!simplify(trial, m, trial_values, literal) ||
            !propagate(trial, m, trial_values, nullptr, nullptr)) continue;
        int next2, next3, nextden;
        flows(trial, m, n, next2, next3, nextden);
        std::int64_t numerator = static_cast<std::int64_t>(next2) * oldden -
                                 static_cast<std::int64_t>(old2) * nextden;
        std::int64_t denominator = static_cast<std::int64_t>(next3) * oldden -
                                   static_cast<std::int64_t>(old3) * nextden;
        if (denominator == 0) continue;
        if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
        if (!found || numerator * best_den > best_num * denominator ||
            (numerator * best_den == best_num * denominator &&
             (i < best_i || (i == best_i && j < best_j)))) {
            found = true; best_num = numerator; best_den = denominator;
            best_i = i; best_j = j;
        }
    }
    return found;
}
} // namespace

extern "C" std::int64_t random_3sat_cl_bucket_heuristic(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 99) return -1;
    if (input[0] < 1 || input[0] > N || input[1] < 0 || input[1] > M ||
        length != 2 + 4 * static_cast<std::size_t>(input[1])) return -1;
    const int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    Formula formula{};
    for (int c = 0; c < m; ++c) {
        const std::size_t base = 2 + 4 * static_cast<std::size_t>(c);
        if (input[base] < 1 || input[base] > 3) return -1;
        formula.lengths[c] = static_cast<int>(input[base]);
        std::array<bool, N> seen{};
        for (int j = 0; j < 3; ++j) {
            const std::int64_t x = input[base + 1 + static_cast<std::size_t>(j)];
            if (j < formula.lengths[c]) {
                if (x == 0 || x < -n || x > n) return -1;
                const int v = static_cast<int>(x > 0 ? x : -x) - 1;
                if (seen[v]) return -1;
                seen[v] = true;
                formula.literals[c][j] = static_cast<int>(x);
            } else if (x != 0) return -1;
        }
        formula.active[c] = true;
    }

    std::array<int, N> values{};
    std::array<Event, N> events{};
    int count = 0;
    int status = 0;
    if (!propagate(formula, m, values, &events, &count)) status = 1;
    while (status == 0) {
        bool pending = false;
        for (int v = 0; v < n; ++v) if (values[v] == 0) pending = true;
        if (!pending) break;
        int bi = -1, bj = -1;
        if (!choose(formula, m, n, values, bi, bj)) { status = 2; break; }
        const int literal = member(formula, m, n, values, bi, bj);
        if (literal == 0) { status = 2; break; }
        events[count++] = {literal, 0, bi, bj};
        if (!simplify(formula, m, values, literal)) { status = 1; break; }
        if (!propagate(formula, m, values, &events, &count)) { status = 1; break; }
    }

    std::array<std::int64_t, WORDS> words{};
    int at = 0, assigned = 0;
    words[at++] = status; words[at++] = n;
    for (int v = 0; v < n; ++v) assigned += values[v] != 0;
    words[at++] = assigned;
    for (int v = 0; v < n; ++v) words[at++] = values[v];
    words[at++] = count;
    for (int i = 0; i < count; ++i) {
        words[at++] = events[i].literal; words[at++] = events[i].kind;
        words[at++] = events[i].i; words[at++] = events[i].j;
    }
    const std::size_t bytes = static_cast<std::size_t>(at) * 8;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::uint8_t, OUT_BYTES> staged{};
    for (int i = 0; i < at; ++i) write_word(staged.data(), 8 * static_cast<std::size_t>(i), words[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
