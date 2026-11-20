#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

enum { MAX_A = 4, MAX_P = 4, MAX_RANK = 4, MAX_INPUT = 52, MAX_OUTPUT = 40 };

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

static int lex_less(const int left[MAX_A], const int right[MAX_A], size_t count) {
    for (size_t i = 0; i < count; ++i) {
        if (left[i] != right[i]) return left[i] < right[i];
    }
    return 0;
}

static void maximum_matching(size_t applicants, size_t posts, int phase,
                             int rank[MAX_A][MAX_P], bool blocked[MAX_A][MAX_P],
                             int assignment[MAX_A], int owner[MAX_P]) {
    size_t limit = 1;
    for (size_t i = 0; i < applicants; ++i) limit *= posts + 1;
    int best[MAX_A] = {0};
    int best_size = -1;
    for (size_t code = 0; code < limit; ++code) {
        size_t value = code;
        int candidate[MAX_A] = {0};
        unsigned used = 0;
        int size = 0;
        int valid = 1;
        for (size_t a = 0; a < applicants; ++a) {
            const int post = (int)(value % (posts + 1));
            value /= posts + 1;
            candidate[a] = post;
            if ((size_t)post == posts) continue;
            if (rank[a][post] == 0 || rank[a][post] > phase || blocked[a][post]
                    || (used & (1u << post)) != 0) {
                valid = 0;
                break;
            }
            used |= 1u << post;
            ++size;
        }
        if (valid && (size > best_size
                || (size == best_size && lex_less(candidate, best, applicants)))) {
            best_size = size;
            for (size_t a = 0; a < applicants; ++a) best[a] = candidate[a];
        }
    }
    for (size_t a = 0; a < applicants; ++a) assignment[a] = -1;
    for (size_t p = 0; p < posts; ++p) owner[p] = -1;
    for (size_t a = 0; a < applicants; ++a) {
        if ((size_t)best[a] < posts) {
            assignment[a] = best[a];
            owner[best[a]] = (int)a;
        }
    }
}

static void classify_vertices(size_t applicants, size_t posts, int phase,
                              int rank[MAX_A][MAX_P], bool blocked[MAX_A][MAX_P],
                              int assignment[MAX_A], int owner[MAX_P],
                              int classes[MAX_A + MAX_P]) {
    int queue[MAX_A + MAX_P];
    size_t head = 0, tail = 0;
    for (size_t v = 0; v < applicants + posts; ++v) classes[v] = 2;
    for (size_t a = 0; a < applicants; ++a) {
        if (assignment[a] < 0) { classes[a] = 0; queue[tail++] = (int)a; }
    }
    for (size_t p = 0; p < posts; ++p) {
        if (owner[p] < 0) { classes[applicants + p] = 0; queue[tail++] = (int)(applicants + p); }
    }
    while (head < tail) {
        const int vertex = queue[head++];
        if ((size_t)vertex < applicants) {
            const size_t a = (size_t)vertex;
            if (classes[vertex] == 0) {
                for (size_t p = 0; p < posts; ++p) {
                    const size_t target = applicants + p;
                    if (rank[a][p] > 0 && rank[a][p] <= phase && !blocked[a][p]
                            && assignment[a] != (int)p && classes[target] == 2) {
                        classes[target] = 1;
                        queue[tail++] = (int)target;
                    }
                }
            } else if (assignment[a] >= 0) {
                const size_t target = applicants + (size_t)assignment[a];
                if (classes[target] == 2) { classes[target] = 0; queue[tail++] = (int)target; }
            }
        } else {
            const size_t p = (size_t)vertex - applicants;
            if (classes[vertex] == 0) {
                for (size_t a = 0; a < applicants; ++a) {
                    if (rank[a][p] > 0 && rank[a][p] <= phase && !blocked[a][p]
                            && assignment[a] != (int)p && classes[a] == 2) {
                        classes[a] = 1;
                        queue[tail++] = (int)a;
                    }
                }
            } else if (owner[p] >= 0 && classes[owner[p]] == 2) {
                classes[owner[p]] = 0;
                queue[tail++] = owner[p];
            }
        }
    }
}

int64_t rank_maximal_matching_irving(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_A || input[1] < 1 || input[1] > MAX_P) return -1;
    const size_t applicants = (size_t)input[0], posts = (size_t)input[1];
    if (input[2] < (int64_t)applicants || input[2] > (int64_t)(applicants * posts)) return -1;
    const size_t edges = (size_t)input[2];
    if (edges > 16 || length != 3 + 3 * edges) return -1;

    int rank[MAX_A][MAX_P] = {{0}};
    size_t degree[MAX_A] = {0};
    int max_rank = 0;
    for (size_t e = 0; e < edges; ++e) {
        const size_t at = 3 + 3 * e;
        const int64_t a64 = input[at], p64 = input[at + 1], r64 = input[at + 2];
        if (a64 < 0 || a64 >= (int64_t)applicants || p64 < 0 || p64 >= (int64_t)posts
                || r64 < 1 || r64 > MAX_RANK) return -1;
        const size_t a = (size_t)a64, p = (size_t)p64;
        if (rank[a][p] != 0) return -1;
        rank[a][p] = (int)r64;
        ++degree[a];
        if (r64 > max_rank) max_rank = (int)r64;
    }
    for (size_t a = 0; a < applicants; ++a) if (degree[a] == 0) return -1;

    bool blocked[MAX_A][MAX_P] = {{0}};
    int assignment[MAX_A] = {-1, -1, -1, -1};
    int owner[MAX_P] = {-1, -1, -1, -1};
    for (int phase = 1; phase <= max_rank; ++phase) {
        maximum_matching(applicants, posts, phase, rank, blocked, assignment, owner);
        int classes[MAX_A + MAX_P];
        classify_vertices(applicants, posts, phase, rank, blocked,
                          assignment, owner, classes);
        for (size_t a = 0; a < applicants; ++a) {
            for (size_t p = 0; p < posts; ++p) {
                if (rank[a][p] == 0 || blocked[a][p]) continue;
                const int left = classes[a], right = classes[applicants + p];
                if (rank[a][p] <= phase) {
                    if ((left == 1 && right != 0) || (right == 1 && left != 0))
                        blocked[a][p] = true;
                } else if (left != 0 || right != 0) {
                    blocked[a][p] = true;
                }
            }
        }
    }

    int64_t signature[MAX_RANK] = {0, 0, 0, 0};
    for (size_t a = 0; a < applicants; ++a) {
        if (assignment[a] >= 0) ++signature[rank[a][assignment[a]] - 1];
    }
    const size_t output_bytes = 8u * (size_t)(max_rank + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    put_i64(staged, 0, max_rank);
    for (int i = 0; i < max_rank; ++i) put_i64(staged, 8u * (size_t)(i + 1), signature[i]);
    for (size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return (int64_t)output_bytes;
}
