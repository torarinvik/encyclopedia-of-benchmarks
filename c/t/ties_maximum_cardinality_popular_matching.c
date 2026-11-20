// Bounded clean-room tied-list maximum-cardinality popular matching.
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { A_MAX = 4, P_MAX = 4, RIGHT_MAX = 8, INPUT_MAX = 52, NODE_MAX = 12 };

static bool augment(int applicant, int right_count, const bool edges[A_MAX][RIGHT_MAX],
                    int left_owner[A_MAX], int right_owner[RIGHT_MAX],
                    bool seen[RIGHT_MAX]) {
    for (int post = 0; post < right_count; ++post) {
        if (!edges[applicant][post] || seen[post]) continue;
        seen[post] = true;
        const int previous = right_owner[post];
        if (previous < 0 || augment(previous, right_count, edges, left_owner, right_owner, seen)) {
            right_owner[post] = applicant;
            left_owner[applicant] = post;
            return true;
        }
    }
    return false;
}

static bool maximum_matching(int applicants, int right_count,
                             const bool edges[A_MAX][RIGHT_MAX],
                             const int initial[A_MAX], int left_owner[A_MAX],
                             int right_owner[RIGHT_MAX]) {
    for (int a = 0; a < A_MAX; ++a) left_owner[a] = initial == NULL ? -1 : initial[a];
    for (int p = 0; p < RIGHT_MAX; ++p) right_owner[p] = -1;
    for (int a = 0; a < applicants; ++a) if (left_owner[a] >= 0) {
        const int p = left_owner[a];
        if (p >= right_count || right_owner[p] >= 0 || !edges[a][p]) return false;
        right_owner[p] = a;
    }
    for (;;) {
        bool changed = false;
        for (int a = 0; a < applicants; ++a) if (left_owner[a] < 0) {
            bool seen[RIGHT_MAX] = { false };
            if (augment(a, right_count, edges, left_owner, right_owner, seen)) changed = true;
        }
        if (!changed) return true;
    }
}

static int solve(int applicants, int posts, const int ranks[A_MAX][P_MAX],
                 const int max_rank[A_MAX]) {
    const int right_count = posts + applicants;
    bool first_edges[A_MAX][RIGHT_MAX] = { { false } };
    for (int a = 0; a < applicants; ++a)
        for (int p = 0; p < posts; ++p) first_edges[a][p] = ranks[a][p] == 1;

    int first_left[A_MAX], first_right[RIGHT_MAX];
    if (!maximum_matching(applicants, right_count, first_edges, NULL, first_left, first_right)) return 0;
    int first_size = 0;
    for (int a = 0; a < applicants; ++a) if (first_left[a] >= 0) ++first_size;

    int state[NODE_MAX];
    int queue[NODE_MAX];
    for (int i = 0; i < applicants + right_count; ++i) state[i] = -1;
    int tail = 0;
    for (int a = 0; a < applicants; ++a) if (first_left[a] < 0) {
        state[a] = 0; queue[tail++] = a;
    }
    for (int p = 0; p < posts; ++p) if (first_right[p] < 0) {
        const int node = applicants + p;
        state[node] = 0; queue[tail++] = node;
    }
    for (int a = 0; a < applicants; ++a) {
        const int node = applicants + posts + a;
        state[node] = 0; queue[tail++] = node;
    }
    for (int head = 0; head < tail; ++head) {
        const int node = queue[head];
        if (node < applicants) {
            const int a = node;
            if (state[node] == 0) {
                for (int p = 0; p < posts; ++p)
                    if (ranks[a][p] == 1 && first_left[a] != p) {
                        const int target = applicants + p;
                        if (state[target] < 0) { state[target] = 1; queue[tail++] = target; }
                    }
            } else if (first_left[a] >= 0) {
                const int target = applicants + first_left[a];
                if (state[target] < 0) { state[target] = 0; queue[tail++] = target; }
            }
        } else {
            const int p = node - applicants;
            if (p < posts) {
                if (state[node] == 0) {
                    for (int a = 0; a < applicants; ++a)
                        if (ranks[a][p] == 1 && first_left[a] != p && state[a] < 0) {
                            state[a] = 1; queue[tail++] = a;
                        }
                } else if (first_right[p] >= 0) {
                    const int target = first_right[p];
                    if (state[target] < 0) { state[target] = 0; queue[tail++] = target; }
                }
            }
        }
    }

    int classes[NODE_MAX];
    for (int i = 0; i < applicants + right_count; ++i) classes[i] = state[i] < 0 ? 2 : state[i];
    bool allowed[A_MAX][RIGHT_MAX] = { { false } };
    for (int a = 0; a < applicants; ++a) {
        int best_even_rank = posts + 1;
        for (int p = 0; p < posts; ++p)
            if (ranks[a][p] > 0 && classes[applicants + p] == 0 && ranks[a][p] < best_even_rank)
                best_even_rank = ranks[a][p];
        const int last_rank = max_rank[a] + 1;
        if (classes[applicants + posts + a] == 0 && last_rank < best_even_rank)
            best_even_rank = last_rank;
        for (int p = 0; p < posts; ++p) {
            bool reduced = ranks[a][p] == 1;
            if (ranks[a][p] > 0 && ranks[a][p] == best_even_rank && classes[applicants + p] == 0)
                reduced = true;
            if (!reduced) continue;
            const int ac = classes[a], pc = classes[applicants + p];
            if ((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1)) continue;
            allowed[a][p] = true;
        }
        if (last_rank == best_even_rank && classes[applicants + posts + a] == 0) {
            const int p = posts + a;
            const int ac = classes[a], pc = classes[applicants + p];
            if (!((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1))) allowed[a][p] = true;
        }
    }
    for (int a = 0; a < applicants; ++a)
        if (first_left[a] >= 0 && !allowed[a][first_left[a]]) return 0;

    int popular_left[A_MAX], temporary_right[RIGHT_MAX];
    if (!maximum_matching(applicants, right_count, allowed, first_left, popular_left, temporary_right)) return 0;
    int rank_one = 0;
    for (int a = 0; a < applicants; ++a) {
        if (popular_left[a] < 0) return 0;
        if (popular_left[a] < posts && ranks[a][popular_left[a]] == 1) ++rank_one;
    }
    if (rank_one != first_size) return 0;

    bool real_edges[A_MAX][RIGHT_MAX] = { { false } };
    int initial_real[A_MAX] = { -1, -1, -1, -1 };
    for (int a = 0; a < applicants; ++a) {
        initial_real[a] = popular_left[a] < posts ? popular_left[a] : -1;
        for (int p = 0; p < posts; ++p) real_edges[a][p] = allowed[a][p];
    }
    int real_left[A_MAX];
    if (!maximum_matching(applicants, right_count, real_edges, initial_real, real_left, temporary_right)) return 0;
    rank_one = 0;
    for (int a = 0; a < applicants; ++a)
        if (real_left[a] >= 0 && real_left[a] < posts && ranks[a][real_left[a]] == 1) ++rank_one;
    if (rank_one != first_size) return 0;

    int final_left[A_MAX];
    if (!maximum_matching(applicants, right_count, allowed, real_left, final_left, temporary_right)) return 0;
    int result = 0;
    rank_one = 0;
    for (int a = 0; a < applicants; ++a) {
        if (final_left[a] < 0) return 0;
        if (final_left[a] < posts) {
            ++result;
            if (ranks[a][final_left[a]] == 1) ++rank_one;
        }
    }
    return rank_one == first_size ? result : 0;
}

int64_t ties_maximum_cardinality_popular_matching(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > INPUT_MAX) return -1;
    const int64_t av = input[0], pv = input[1], ev = input[2];
    if (av < 1 || av > A_MAX || pv < 1 || pv > P_MAX || ev < av || ev > av * pv) return -1;
    const int applicants = (int)av, posts = (int)pv, edge_count = (int)ev;
    if (length != (size_t)(3 + 3 * edge_count)) return -1;
    int ranks[A_MAX][P_MAX] = { { 0 } };
    int max_rank[A_MAX] = { 0 };
    size_t cursor = 3;
    for (int i = 0; i < edge_count; ++i) {
        const int64_t a64 = input[cursor++], p64 = input[cursor++], r64 = input[cursor++];
        if (a64 < 0 || a64 >= applicants || p64 < 0 || p64 >= posts || r64 < 1 || r64 > posts) return -1;
        const int a = (int)a64, p = (int)p64, rank = (int)r64;
        if (ranks[a][p] != 0) return -1;
        ranks[a][p] = rank;
        if (rank > max_rank[a]) max_rank[a] = rank;
    }
    bool has_tie = false;
    for (int a = 0; a < applicants; ++a) {
        int counts[P_MAX + 1] = { 0 };
        for (int p = 0; p < posts; ++p) if (ranks[a][p] > 0) ++counts[ranks[a][p]];
        if (max_rank[a] == 0) return -1;
        for (int rank = 1; rank <= max_rank[a]; ++rank) if (counts[rank] == 0) return -1;
        for (int rank = 1; rank <= max_rank[a]; ++rank) if (counts[rank] > 1) has_tie = true;
    }
    if (!has_tie) return -1;
    return solve(applicants, posts, ranks, max_rank);
}
