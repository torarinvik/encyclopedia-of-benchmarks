#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 4;
constexpr std::size_t max_parseable_length = 34;

struct Matching {
    int n = 0;
    bool engaged[max_n][max_n]{};
    int assignment[max_n]{};
    int best[max_n]{};
    int best_size = -1;
};

void enumerate_matching(Matching& state, int man, int used, int size) noexcept {
    if (man == state.n) {
        if (size > state.best_size) {
            state.best_size = size;
            for (int i = 0; i < state.n; ++i) state.best[i] = state.assignment[i];
        }
        return;
    }
    for (int woman = 0; woman < state.n; ++woman) {
        if (state.engaged[man][woman] && (used & (1 << woman)) == 0) {
            state.assignment[man] = woman;
            enumerate_matching(state, man + 1, used | (1 << woman), size + 1);
        }
    }
    state.assignment[man] = state.n;
    enumerate_matching(state, man + 1, used, size);
}

bool dense_ranks(const int rank[max_n][max_n], int n, bool rows_are_people) noexcept {
    for (int person = 0; person < n; ++person) {
        int maximum = 0;
        for (int partner = 0; partner < n; ++partner) {
            const int value = rows_are_people ? rank[person][partner] : rank[partner][person];
            if (value > maximum) maximum = value;
        }
        for (int level = 1; level <= maximum; ++level) {
            bool found = false;
            for (int partner = 0; partner < n; ++partner) {
                const int value = rows_are_people ? rank[person][partner] : rank[partner][person];
                if (value == level) found = true;
            }
            if (!found) return false;
        }
    }
    return true;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto n_raw = input[0];
    if (n_raw < 1 || n_raw > max_n) return -1;
    const int n = static_cast<int>(n_raw);
    const auto side = static_cast<std::size_t>(n) * static_cast<std::size_t>(n);
    if (length != 1 + 2 * side) return -1;

    int men_rank[max_n][max_n]{};
    int women_rank[max_n][max_n]{};
    for (int man = 0; man < n; ++man) {
        for (int woman = 0; woman < n; ++woman) {
            const auto rank = input[1 + static_cast<std::size_t>(man) * n + woman];
            if (rank < 0 || rank > n) return -1;
            men_rank[man][woman] = static_cast<int>(rank);
        }
    }
    for (int woman = 0; woman < n; ++woman) {
        for (int man = 0; man < n; ++man) {
            const auto rank = input[1 + side + static_cast<std::size_t>(woman) * n + man];
            if (rank < 0 || rank > n || ((rank > 0) != (men_rank[man][woman] > 0))) return -1;
            women_rank[woman][man] = static_cast<int>(rank);
        }
    }
    if (!dense_ranks(men_rank, n, true) || !dense_ranks(women_rank, n, false)) return -1;

    bool alive[max_n][max_n]{};
    bool engaged[max_n][max_n]{};
    bool proposed_woman[max_n]{};
    for (int man = 0; man < n; ++man)
        for (int woman = 0; woman < n; ++woman)
            alive[man][woman] = men_rank[man][woman] > 0;

    for (;;) {
        int proposer = -1;
        for (int man = 0; man < n && proposer < 0; ++man) {
            bool has_engagement = false, has_choice = false;
            for (int woman = 0; woman < n; ++woman) {
                has_engagement = has_engagement || engaged[man][woman];
                has_choice = has_choice || alive[man][woman];
            }
            if (!has_engagement && has_choice) proposer = man;
        }
        if (proposer < 0) break;

        int head_rank = n + 1;
        for (int woman = 0; woman < n; ++woman)
            if (alive[proposer][woman] && men_rank[proposer][woman] < head_rank)
                head_rank = men_rank[proposer][woman];
        for (int woman = 0; woman < n; ++woman) {
            if (!alive[proposer][woman] || men_rank[proposer][woman] != head_rank) continue;
            proposed_woman[woman] = true;
            engaged[proposer][woman] = true;
            for (int successor = 0; successor < n; ++successor) {
                if (alive[successor][woman]
                    && women_rank[woman][successor] > women_rank[woman][proposer]) {
                    engaged[successor][woman] = false;
                    alive[successor][woman] = false;
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
                    engaged[man][woman] = false;
                    if (alive[man][woman] && women_rank[woman][man] == tail_rank)
                        alive[man][woman] = false;
                }
            }
        }
    }

    Matching matching{};
    matching.n = n;
    for (int man = 0; man < n; ++man)
        for (int woman = 0; woman < n; ++woman)
            matching.engaged[man][woman] = engaged[man][woman];
    enumerate_matching(matching, 0, 0, 0);
    bool matched_woman[max_n]{};
    for (int man = 0; man < n; ++man)
        if (matching.best[man] < n) matched_woman[matching.best[man]] = true;
    for (int woman = 0; woman < n; ++woman)
        if (proposed_woman[woman] && !matched_woman[woman]) return -2;
    std::int64_t result = 0;
    for (int man = 0; man < n; ++man) result = result * (n + 1) + matching.best[man];
    return result;
}
}

extern "C" std::int64_t super_stable_matching_ties_incomplete(const std::int64_t* input,
                                                                std::size_t length) noexcept {
    return solve(input, length);
}
