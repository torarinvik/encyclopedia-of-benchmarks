#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 4, MAX_VALID_LENGTH = 33, MAX_PARSEABLE_LENGTH = 34 };

typedef struct {
    int n;
    int engaged[MAX_N][MAX_N];
    int assignment[MAX_N];
    int best[MAX_N];
    int best_size;
} Matching;

static void enumerate_matching(Matching *state, int man, int used, int size) {
    if (man == state->n) {
        if (size > state->best_size) {
            state->best_size = size;
            for (int i = 0; i < state->n; ++i) state->best[i] = state->assignment[i];
        }
        return;
    }
    for (int woman = 0; woman < state->n; ++woman) {
        if (state->engaged[man][woman] && (used & (1 << woman)) == 0) {
            state->assignment[man] = woman;
            enumerate_matching(state, man + 1, used | (1 << woman), size + 1);
        }
    }
    state->assignment[man] = state->n;
    enumerate_matching(state, man + 1, used, size);
}

static int dense_ranks(const int rank[MAX_N][MAX_N], int n, int rows_are_people) {
    for (int person = 0; person < n; ++person) {
        int maximum = 0;
        for (int partner = 0; partner < n; ++partner) {
            int value = rows_are_people ? rank[person][partner] : rank[partner][person];
            if (value > maximum) maximum = value;
        }
        for (int level = 1; level <= maximum; ++level) {
            int found = 0;
            for (int partner = 0; partner < n; ++partner) {
                int value = rows_are_people ? rank[person][partner] : rank[partner][person];
                if (value == level) found = 1;
            }
            if (!found) return 0;
        }
    }
    return 1;
}

int64_t super_stable_matching_ties_incomplete(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > MAX_N) return -1;
    const int n = (int)n_raw;
    if (length != (size_t)(1 + 2 * n * n)) return -1;

    int men_rank[MAX_N][MAX_N] = {{0}};
    int women_rank[MAX_N][MAX_N] = {{0}};
    const size_t side = (size_t)n * (size_t)n;
    for (int man = 0; man < n; ++man) {
        for (int woman = 0; woman < n; ++woman) {
            const int64_t rank = input[1 + (size_t)man * n + woman];
            if (rank < 0 || rank > n) return -1;
            men_rank[man][woman] = (int)rank;
        }
    }
    for (int woman = 0; woman < n; ++woman) {
        for (int man = 0; man < n; ++man) {
            const int64_t rank = input[1 + side + (size_t)woman * n + man];
            if (rank < 0 || rank > n || ((rank > 0) != (men_rank[man][woman] > 0))) return -1;
            women_rank[woman][man] = (int)rank;
        }
    }
    if (!dense_ranks(men_rank, n, 1) || !dense_ranks(women_rank, n, 0)) return -1;

    int alive[MAX_N][MAX_N] = {{0}};
    int engaged[MAX_N][MAX_N] = {{0}};
    int proposed_woman[MAX_N] = {0};
    for (int man = 0; man < n; ++man)
        for (int woman = 0; woman < n; ++woman)
            alive[man][woman] = men_rank[man][woman] > 0;

    for (;;) {
        int proposer = -1;
        for (int man = 0; man < n && proposer < 0; ++man) {
            int is_engaged = 0, has_choice = 0;
            for (int woman = 0; woman < n; ++woman) {
                if (engaged[man][woman]) is_engaged = 1;
                if (alive[man][woman]) has_choice = 1;
            }
            if (!is_engaged && has_choice) proposer = man;
        }
        if (proposer < 0) break;

        int head_rank = n + 1;
        for (int woman = 0; woman < n; ++woman)
            if (alive[proposer][woman] && men_rank[proposer][woman] < head_rank)
                head_rank = men_rank[proposer][woman];
        for (int woman = 0; woman < n; ++woman) {
            if (!alive[proposer][woman] || men_rank[proposer][woman] != head_rank) continue;
            proposed_woman[woman] = 1;
            engaged[proposer][woman] = 1;
            for (int successor = 0; successor < n; ++successor) {
                if (alive[successor][woman]
                    && women_rank[woman][successor] > women_rank[woman][proposer]) {
                    engaged[successor][woman] = 0;
                    alive[successor][woman] = 0;
                }
            }
        }

        for (int woman = 0; woman < n; ++woman) {
            int count = 0, tail_rank = 0;
            for (int man = 0; man < n; ++man) {
                if (engaged[man][woman]) ++count;
                if (alive[man][woman] && women_rank[woman][man] > tail_rank)
                    tail_rank = women_rank[woman][man];
            }
            if (count > 1) {
                for (int man = 0; man < n; ++man) {
                    engaged[man][woman] = 0;
                    if (alive[man][woman] && women_rank[woman][man] == tail_rank)
                        alive[man][woman] = 0;
                }
            }
        }
    }

    Matching matching = {0};
    matching.n = n;
    matching.best_size = -1;
    for (int man = 0; man < n; ++man)
        for (int woman = 0; woman < n; ++woman)
            matching.engaged[man][woman] = engaged[man][woman];
    enumerate_matching(&matching, 0, 0, 0);
    int matched_woman[MAX_N] = {0};
    for (int man = 0; man < n; ++man)
        if (matching.best[man] < n) matched_woman[matching.best[man]] = 1;
    for (int woman = 0; woman < n; ++woman)
        if (proposed_woman[woman] && !matched_woman[woman]) return -2;

    int64_t result = 0;
    for (int man = 0; man < n; ++man)
        result = result * (n + 1) + matching.best[man];
    return result;
}
