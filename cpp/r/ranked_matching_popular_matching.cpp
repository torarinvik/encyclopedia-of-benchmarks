#include <cstddef>
#include <cstdint>

enum { MAX_A = 4, MAX_P = 4, MAX_POSTS = 8, MAX_NODES = 12,
       MAX_INPUT = 51, MAX_OUTPUT = 40 };

static void put64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8u * b));
}

static int lex_less(const int *left, const int *right, size_t count) {
    for (size_t i = 0; i < count; ++i) {
        if (left[i] != right[i]) return left[i] < right[i];
    }
    return 0;
}

extern "C" int64_t ranked_matching_popular_matching(const int64_t *input, size_t length,
                                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6u || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_A || input[1] < 1 || input[1] > MAX_P) return -1;
    const size_t applicants = (size_t)input[0], posts = (size_t)input[1];
    if (input[2] < (int64_t)applicants || input[2] > (int64_t)(applicants * posts)) return -1;
    const size_t edges = (size_t)input[2];
    if (length != 3u + 3u * edges) return -1;
    const size_t post_count = posts + applicants;
    const size_t node_count = applicants + post_count;
    const size_t output_bytes = 8u * (applicants + 1u);
    int rank[MAX_A][MAX_P] = {{0}}, max_rank[MAX_A] = {0};
    int rank_seen[MAX_A][MAX_P + 1] = {{0}};
    size_t cursor = 3;
    for (size_t e = 0; e < edges; ++e) {
        int64_t a64 = input[cursor], p64 = input[cursor + 1], r64 = input[cursor + 2];
        cursor += 3;
        if (a64 < 0 || a64 >= (int64_t)applicants || p64 < 0 || p64 >= (int64_t)posts ||
            r64 < 1 || r64 > (int64_t)posts) return -1;
        size_t a = (size_t)a64, p = (size_t)p64;
        if (rank[a][p] != 0) return -1;
        rank[a][p] = (int)r64;
        rank_seen[a][(size_t)r64] = 1;
        if (r64 > max_rank[a]) max_rank[a] = (int)r64;
    }
    for (size_t a = 0; a < applicants; ++a) {
        if (max_rank[a] == 0) return -1;
        for (int r = 1; r <= max_rank[a]; ++r) if (!rank_seen[a][r]) return -1;
    }

    /* Canonical maximum matching M1 of the rank-one graph. */
    int best_m1[MAX_A] = {0}, best_m1_size = -1;
    int m1_limit = 1;
    for (size_t a = 0; a < applicants; ++a) m1_limit *= (int)(posts + 1u);
    for (int code = 0; code < m1_limit; ++code) {
        int value = code, candidate[MAX_A] = {0}, used = 0, count = 0, valid = 1;
        for (size_t a = 0; a < applicants; ++a) {
            int post = value % (int)(posts + 1u);
            value /= (int)(posts + 1u);
            candidate[a] = post;
            if ((size_t)post == posts) continue;
            if (rank[a][post] != 1 || (used & (1 << post))) { valid = 0; break; }
            used |= 1 << post;
            ++count;
        }
        if (valid && (count > best_m1_size ||
            (count == best_m1_size && lex_less(candidate, best_m1, applicants)))) {
            best_m1_size = count;
            for (size_t a = 0; a < applicants; ++a) best_m1[a] = candidate[a];
        }
    }

    int mate_a[MAX_A], mate_p[MAX_P], parity[MAX_NODES];
    for (size_t a = 0; a < applicants; ++a) mate_a[a] = -1;
    for (size_t p = 0; p < posts; ++p) mate_p[p] = -1;
    for (size_t a = 0; a < applicants; ++a) if ((size_t)best_m1[a] < posts) {
        mate_a[a] = best_m1[a];
        mate_p[best_m1[a]] = (int)a;
    }
    for (size_t n = 0; n < node_count; ++n) parity[n] = -1;
    int queue[MAX_NODES];
    size_t head = 0, tail = 0;
    for (size_t a = 0; a < applicants; ++a) if (mate_a[a] < 0) {
        parity[a] = 0; queue[tail++] = (int)a;
    }
    for (size_t p = 0; p < posts; ++p) if (mate_p[p] < 0) {
        size_t node = applicants + p; parity[node] = 0; queue[tail++] = (int)node;
    }
    for (size_t p = posts; p < post_count; ++p) {
        size_t node = applicants + p; parity[node] = 0; queue[tail++] = (int)node;
    }
    while (head < tail) {
        int node = queue[head++];
        if ((size_t)node < applicants) {
            size_t a = (size_t)node;
            if (parity[node] == 0) {
                for (size_t p = 0; p < posts; ++p) if (rank[a][p] == 1 && mate_a[a] != (int)p) {
                    int target = (int)(applicants + p);
                    if (parity[target] < 0) { parity[target] = 1; queue[tail++] = target; }
                }
            } else if (mate_a[a] >= 0) {
                int target = (int)(applicants + (size_t)mate_a[a]);
                if (parity[target] < 0) { parity[target] = 0; queue[tail++] = target; }
            }
        } else {
            size_t p = (size_t)node - applicants;
            if (p < posts) {
                if (parity[node] == 0) {
                    for (size_t a = 0; a < applicants; ++a) if (rank[a][p] == 1 && mate_a[a] != (int)p && parity[a] < 0) {
                        parity[a] = 1; queue[tail++] = (int)a;
                    }
                } else if (mate_p[p] >= 0 && parity[mate_p[p]] < 0) {
                    parity[mate_p[p]] = 0; queue[tail++] = mate_p[p];
                }
            }
        }
    }

    int class_of[MAX_NODES];
    for (size_t n = 0; n < node_count; ++n) class_of[n] = parity[n] < 0 ? 2 : parity[n];
    int reduced[MAX_A][MAX_POSTS] = {{0}}, allowed[MAX_A][MAX_POSTS] = {{0}};
    for (size_t a = 0; a < applicants; ++a) {
        int best_even_rank = (int)posts + 1;
        for (size_t p = 0; p < posts; ++p) {
            if (rank[a][p] == 1) reduced[a][p] = 1;
            if (rank[a][p] > 0 && class_of[applicants + p] == 0 && rank[a][p] < best_even_rank)
                best_even_rank = rank[a][p];
        }
        const int last_rank = max_rank[a] + 1;
        if (class_of[applicants + posts + a] == 0 && last_rank < best_even_rank) best_even_rank = last_rank;
        for (size_t p = 0; p < posts; ++p)
            if (rank[a][p] > 0 && rank[a][p] == best_even_rank && class_of[applicants + p] == 0) reduced[a][p] = 1;
        if (last_rank == best_even_rank && class_of[applicants + posts + a] == 0)
            reduced[a][posts + a] = 1;
        for (size_t p = 0; p < post_count; ++p) {
            int ca = class_of[a], cp = class_of[applicants + p];
            if (reduced[a][p] && !((ca == 1 && (cp == 1 || cp == 2)) || (ca == 2 && cp == 1)))
                allowed[a][p] = 1;
        }
    }

    int best[MAX_A] = {0}, found = 0;
    int full_limit = 1;
    for (size_t a = 0; a < applicants; ++a) full_limit *= (int)post_count;
    for (int code = 0; code < full_limit; ++code) {
        int value = code, candidate[MAX_A] = {0}, used = 0, first_count = 0, valid = 1;
        for (size_t a = 0; a < applicants; ++a) {
            int post = value % (int)post_count;
            value /= (int)post_count;
            candidate[a] = post;
            if (!allowed[a][post] || (used & (1 << post))) { valid = 0; break; }
            used |= 1 << post;
            if ((size_t)post < posts && rank[a][post] == 1) ++first_count;
        }
        if (valid && first_count == best_m1_size && (!found || lex_less(candidate, best, applicants))) {
            found = 1;
            for (size_t a = 0; a < applicants; ++a) best[a] = candidate[a];
        }
    }
    if (output == NULL || capacity < output_bytes) return -2;
    if (!found) for (size_t a = 0; a < applicants; ++a) best[a] = -1;
    uint8_t staged[MAX_OUTPUT] = {0};
    put64(staged, 0, found ? 1 : 0);
    for (size_t a = 0; a < applicants; ++a) put64(staged, 8u * (a + 1u), best[a]);
    for (size_t b = 0; b < output_bytes; ++b) output[b] = staged[b];
    return (int64_t)output_bytes;
}
