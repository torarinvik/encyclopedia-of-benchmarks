// Bounded clean-room tied-list maximum-cardinality popular matching.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int A = 4, P = 4, R = 8, INPUT_MAX = 52, NODES = 12;
using Edges = std::array<std::array<bool, R>, A>;
using Left = std::array<int, A>;
using Right = std::array<int, R>;
using Ranks = std::array<std::array<int, P>, A>;

bool augment(int a, int right_count, const Edges& edges, Left& left, Right& right,
             std::array<bool, R>& seen) {
    for (int p = 0; p < right_count; ++p) {
        if (!edges[a][p] || seen[p]) continue;
        seen[p] = true;
        const int previous = right[p];
        if (previous < 0 || augment(previous, right_count, edges, left, right, seen)) {
            right[p] = a;
            left[a] = p;
            return true;
        }
    }
    return false;
}

bool maximum_matching(int applicants, int right_count, const Edges& edges,
                      const Left* initial, Left& left, Right& right) {
    left.fill(-1);
    right.fill(-1);
    if (initial != nullptr) left = *initial;
    for (int a = 0; a < applicants; ++a) if (left[a] >= 0) {
        const int p = left[a];
        if (p >= right_count || right[p] >= 0 || !edges[a][p]) return false;
        right[p] = a;
    }
    for (;;) {
        bool changed = false;
        for (int a = 0; a < applicants; ++a) if (left[a] < 0) {
            std::array<bool, R> seen{};
            if (augment(a, right_count, edges, left, right, seen)) changed = true;
        }
        if (!changed) return true;
    }
}

int solve(int applicants, int posts, const Ranks& ranks, const std::array<int, A>& max_rank) {
    const int right_count = posts + applicants;
    Edges first_edges{};
    for (int a = 0; a < applicants; ++a)
        for (int p = 0; p < posts; ++p) first_edges[a][p] = ranks[a][p] == 1;
    Left first_left{};
    Right first_right{};
    if (!maximum_matching(applicants, right_count, first_edges, nullptr, first_left, first_right)) return 0;
    int first_size = 0;
    for (int a = 0; a < applicants; ++a) first_size += first_left[a] >= 0;

    std::array<int, NODES> state;
    state.fill(-1);
    std::array<int, NODES> queue{};
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
                for (int p = 0; p < posts; ++p) if (ranks[a][p] == 1 && first_left[a] != p) {
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
    std::array<int, NODES> classes{};
    for (int i = 0; i < applicants + right_count; ++i) classes[i] = state[i] < 0 ? 2 : state[i];
    Edges allowed{};
    for (int a = 0; a < applicants; ++a) {
        int best_even_rank = posts + 1;
        for (int p = 0; p < posts; ++p)
            if (ranks[a][p] > 0 && classes[applicants + p] == 0)
                best_even_rank = std::min(best_even_rank, ranks[a][p]);
        const int last_rank = max_rank[a] + 1;
        if (classes[applicants + posts + a] == 0) best_even_rank = std::min(best_even_rank, last_rank);
        for (int p = 0; p < posts; ++p) {
            if (ranks[a][p] != 1 && !(ranks[a][p] > 0 && ranks[a][p] == best_even_rank
                                       && classes[applicants + p] == 0)) continue;
            const int ac = classes[a], pc = classes[applicants + p];
            if ((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1)) continue;
            allowed[a][p] = true;
        }
        if (last_rank == best_even_rank && classes[applicants + posts + a] == 0) {
            const int p = posts + a, ac = classes[a], pc = classes[applicants + p];
            if (!((ac == 1 && (pc == 1 || pc == 2)) || (ac == 2 && pc == 1))) allowed[a][p] = true;
        }
    }
    for (int a = 0; a < applicants; ++a)
        if (first_left[a] >= 0 && !allowed[a][first_left[a]]) return 0;

    Left popular_left{};
    Right temp_right{};
    if (!maximum_matching(applicants, right_count, allowed, &first_left, popular_left, temp_right)) return 0;
    int rank_one = 0;
    for (int a = 0; a < applicants; ++a) {
        if (popular_left[a] < 0) return 0;
        if (popular_left[a] < posts && ranks[a][popular_left[a]] == 1) ++rank_one;
    }
    if (rank_one != first_size) return 0;

    Edges real_edges{};
    Left initial_real{};
    initial_real.fill(-1);
    for (int a = 0; a < applicants; ++a) {
        initial_real[a] = popular_left[a] < posts ? popular_left[a] : -1;
        for (int p = 0; p < posts; ++p) real_edges[a][p] = allowed[a][p];
    }
    Left real_left{};
    if (!maximum_matching(applicants, right_count, real_edges, &initial_real, real_left, temp_right)) return 0;
    rank_one = 0;
    for (int a = 0; a < applicants; ++a) if (real_left[a] >= 0 && real_left[a] < posts
        && ranks[a][real_left[a]] == 1) ++rank_one;
    if (rank_one != first_size) return 0;
    Left final_left{};
    if (!maximum_matching(applicants, right_count, allowed, &real_left, final_left, temp_right)) return 0;
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
} // namespace

extern "C" std::int64_t ties_maximum_cardinality_popular_matching(const std::int64_t* input,
                                                                   std::size_t length) {
    if (input == nullptr || length < 3 || length > 52) return -1;
    const auto av = input[0], pv = input[1], ev = input[2];
    if (av < 1 || av > 4 || pv < 1 || pv > 4 || ev < av || ev > av * pv) return -1;
    const int applicants = static_cast<int>(av), posts = static_cast<int>(pv), edges = static_cast<int>(ev);
    if (length != static_cast<std::size_t>(3 + 3 * edges)) return -1;
    Ranks ranks{};
    std::array<int, A> max_rank{};
    std::size_t cursor = 3;
    for (int i = 0; i < edges; ++i) {
        const auto a64 = input[cursor++], p64 = input[cursor++], r64 = input[cursor++];
        if (a64 < 0 || a64 >= applicants || p64 < 0 || p64 >= posts || r64 < 1 || r64 > posts) return -1;
        const int a = static_cast<int>(a64), p = static_cast<int>(p64), rank = static_cast<int>(r64);
        if (ranks[a][p] != 0) return -1;
        ranks[a][p] = rank;
        max_rank[a] = std::max(max_rank[a], rank);
    }
    bool has_tie = false;
    for (int a = 0; a < applicants; ++a) {
        std::array<int, P + 1> counts{};
        for (int p = 0; p < posts; ++p) if (ranks[a][p] > 0) ++counts[ranks[a][p]];
        if (max_rank[a] == 0) return -1;
        for (int rank = 1; rank <= max_rank[a]; ++rank) if (counts[rank] == 0) return -1;
        for (int rank = 1; rank <= max_rank[a]; ++rank) if (counts[rank] > 1) has_tie = true;
    }
    if (!has_tie) return -1;
    return solve(applicants, posts, ranks, max_rank);
}
