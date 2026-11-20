#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t A_MAX = 4, P_MAX = 4, V_MAX = 8, R_MAX = 4;
constexpr std::size_t INPUT_MAX = 52, OUTPUT_MAX = 40;

void store_i64(std::uint8_t* out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}

bool lex_less(const int* x, const int* y, std::size_t n) {
    for (std::size_t i = 0; i < n; ++i) if (x[i] != y[i]) return x[i] < y[i];
    return false;
}

void maximum_matching(std::size_t a_count, std::size_t p_count, int phase,
                      const int rank[A_MAX][P_MAX], const bool blocked[A_MAX][P_MAX],
                      int mate_a[A_MAX], int mate_p[P_MAX]) {
    std::size_t limit = 1;
    for (std::size_t a = 0; a < a_count; ++a) limit *= p_count + 1;
    int best[A_MAX] = {0, 0, 0, 0};
    int best_size = -1;
    for (std::size_t code = 0; code < limit; ++code) {
        std::size_t digits = code;
        int candidate[A_MAX] = {0, 0, 0, 0};
        unsigned used = 0;
        int size = 0;
        bool valid = true;
        for (std::size_t a = 0; a < a_count; ++a) {
            const int p = static_cast<int>(digits % (p_count + 1));
            digits /= p_count + 1;
            candidate[a] = p;
            if (static_cast<std::size_t>(p) == p_count) continue;
            if (rank[a][p] == 0 || rank[a][p] > phase || blocked[a][p] || (used & (1u << p))) {
                valid = false;
                break;
            }
            used |= 1u << p;
            ++size;
        }
        if (valid && (size > best_size || (size == best_size && lex_less(candidate, best, a_count)))) {
            best_size = size;
            for (std::size_t a = 0; a < a_count; ++a) best[a] = candidate[a];
        }
    }
    for (std::size_t a = 0; a < A_MAX; ++a) mate_a[a] = -1;
    for (std::size_t p = 0; p < P_MAX; ++p) mate_p[p] = -1;
    for (std::size_t a = 0; a < a_count; ++a) if (static_cast<std::size_t>(best[a]) < p_count) {
        mate_a[a] = best[a]; mate_p[best[a]] = static_cast<int>(a);
    }
}

void classify(std::size_t a_count, std::size_t p_count, int phase,
              const int rank[A_MAX][P_MAX], const bool blocked[A_MAX][P_MAX],
              const int mate_a[A_MAX], const int mate_p[P_MAX], int cls[V_MAX]) {
    int queue[V_MAX];
    std::size_t head = 0, tail = 0;
    for (std::size_t v = 0; v < a_count + p_count; ++v) cls[v] = 2;
    for (std::size_t a = 0; a < a_count; ++a) if (mate_a[a] < 0) { cls[a] = 0; queue[tail++] = static_cast<int>(a); }
    for (std::size_t p = 0; p < p_count; ++p) if (mate_p[p] < 0) {
        const auto v = a_count + p; cls[v] = 0; queue[tail++] = static_cast<int>(v);
    }
    while (head < tail) {
        const int v = queue[head++];
        if (static_cast<std::size_t>(v) < a_count) {
            const auto a = static_cast<std::size_t>(v);
            if (cls[v] == 0) {
                for (std::size_t p = 0; p < p_count; ++p) {
                    const auto w = a_count + p;
                    if (rank[a][p] && rank[a][p] <= phase && !blocked[a][p] && mate_a[a] != static_cast<int>(p) && cls[w] == 2) {
                        cls[w] = 1; queue[tail++] = static_cast<int>(w);
                    }
                }
            } else if (mate_a[a] >= 0) {
                const auto w = a_count + static_cast<std::size_t>(mate_a[a]);
                if (cls[w] == 2) { cls[w] = 0; queue[tail++] = static_cast<int>(w); }
            }
        } else {
            const auto p = static_cast<std::size_t>(v) - a_count;
            if (cls[v] == 0) {
                for (std::size_t a = 0; a < a_count; ++a) if (rank[a][p] && rank[a][p] <= phase && !blocked[a][p] && mate_a[a] != static_cast<int>(p) && cls[a] == 2) {
                    cls[a] = 1; queue[tail++] = static_cast<int>(a);
                }
            } else if (mate_p[p] >= 0 && cls[mate_p[p]] == 2) {
                cls[mate_p[p]] = 0; queue[tail++] = mate_p[p];
            }
        }
    }
}
} // namespace

extern "C" std::int64_t rank_maximal_matching_irving(const std::int64_t* input, std::size_t length,
                                                       std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 3 || length > INPUT_MAX) return -1;
    if (input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4) return -1;
    const auto a_count = static_cast<std::size_t>(input[0]);
    const auto p_count = static_cast<std::size_t>(input[1]);
    if (input[2] < static_cast<std::int64_t>(a_count) || input[2] > static_cast<std::int64_t>(a_count * p_count)) return -1;
    const auto edges = static_cast<std::size_t>(input[2]);
    if (edges > 16 || length != 3 + 3 * edges) return -1;
    int rank[A_MAX][P_MAX] = {};
    int degree[A_MAX] = {};
    int max_rank = 0;
    for (std::size_t e = 0; e < edges; ++e) {
        const auto at = 3 + 3 * e;
        const auto av = input[at], pv = input[at + 1], rv = input[at + 2];
        if (av < 0 || av >= static_cast<std::int64_t>(a_count) || pv < 0 || pv >= static_cast<std::int64_t>(p_count) || rv < 1 || rv > R_MAX) return -1;
        const auto a = static_cast<std::size_t>(av), p = static_cast<std::size_t>(pv);
        if (rank[a][p]) return -1;
        rank[a][p] = static_cast<int>(rv); ++degree[a];
        if (rv > max_rank) max_rank = static_cast<int>(rv);
    }
    for (std::size_t a = 0; a < a_count; ++a) if (!degree[a]) return -1;

    bool blocked[A_MAX][P_MAX] = {};
    int mate_a[A_MAX] = {-1, -1, -1, -1}, mate_p[P_MAX] = {-1, -1, -1, -1};
    for (int phase = 1; phase <= max_rank; ++phase) {
        maximum_matching(a_count, p_count, phase, rank, blocked, mate_a, mate_p);
        int cls[V_MAX];
        classify(a_count, p_count, phase, rank, blocked, mate_a, mate_p, cls);
        for (std::size_t a = 0; a < a_count; ++a) for (std::size_t p = 0; p < p_count; ++p) {
            if (!rank[a][p] || blocked[a][p]) continue;
            const int ca = cls[a], cp = cls[a_count + p];
            if (rank[a][p] <= phase) {
                if ((ca == 1 && cp != 0) || (cp == 1 && ca != 0)) blocked[a][p] = true;
            } else if (ca != 0 || cp != 0) blocked[a][p] = true;
        }
    }
    std::int64_t signature[R_MAX] = {};
    for (std::size_t a = 0; a < a_count; ++a) if (mate_a[a] >= 0) ++signature[rank[a][mate_a[a]] - 1];
    const auto bytes = 8 * static_cast<std::size_t>(max_rank + 1);
    if (!output || capacity < bytes) return -2;
    std::uint8_t staged[OUTPUT_MAX] = {};
    store_i64(staged, 0, max_rank);
    for (int i = 0; i < max_rank; ++i) store_i64(staged, 8 * static_cast<std::size_t>(i + 1), signature[i]);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
