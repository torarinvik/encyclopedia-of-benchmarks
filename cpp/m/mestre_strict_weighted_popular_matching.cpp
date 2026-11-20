// Clean-room bounded implementation of Mestre's strict weighted profile.
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <vector>

namespace {
constexpr int A = 4, J = 5, N = 9, PARSEABLE = 31, INF = 1'000'000'000;

std::int64_t solve(int a_count, int j_count, const std::array<std::int64_t, A>& weight,
                   const std::array<int, A>& length,
                   const std::array<std::array<int, J>, A>& listed) {
    std::array<std::array<int, N>, A> row{};
    std::array<int, A> row_length{};
    for (int a = 0; a < a_count; ++a) {
        for (int i = 0; i < length[a]; ++i) row[a][row_length[a]++] = listed[a][i];
        row[a][row_length[a]++] = j_count + a;
    }
    std::vector<int> categories;
    for (int a = 0; a < a_count; ++a) categories.push_back(static_cast<int>(weight[a]));
    std::sort(categories.begin(), categories.end(), std::greater<int>());
    categories.erase(std::unique(categories.begin(), categories.end()), categories.end());
    std::array<int, A> category{}, first{}, second{};
    std::array<int, N> f_category; f_category.fill(-1);
    std::array<bool, N> higher{};
    for (int a = 0; a < a_count; ++a) {
        category[a] = static_cast<int>(std::find(categories.begin(), categories.end(), weight[a]) - categories.begin());
    }
    for (int c = 0; c < static_cast<int>(categories.size()); ++c) {
        for (int a = 0; a < a_count; ++a) if (category[a] == c) {
            for (int i = 0; i < row_length[a]; ++i) if (!higher[row[a][i]]) { first[a] = row[a][i]; break; }
        }
        for (int a = 0; a < a_count; ++a) if (category[a] == c) {
            f_category[first[a]] = c; higher[first[a]] = true;
        }
    }
    for (int a = 0; a < a_count; ++a) {
        second[a] = -1;
        for (int i = 0; i < row_length[a]; ++i) {
            const int p = row[a][i];
            if (f_category[p] < 0 || f_category[p] > category[a]) { second[a] = p; break; }
        }
    }
    std::array<int, N> label; label.fill(INF);
    std::array<bool, A> keep_first{}, keep_second{};
    for (int a = 0; a < a_count; ++a) { keep_first[a] = true; keep_second[a] = second[a] >= 0; }
    auto lambda_min = [&](int a, int target) {
        int best = INF;
        for (int i = 0; i < row_length[a]; ++i) {
            const int p = row[a][i];
            if (p == target) break;
            if (f_category[p] >= 0) best = std::min(best, label[p]);
        }
        return best;
    };
    for (int c = 0; c < static_cast<int>(categories.size()); ++c) {
        const int w = categories[c];
        if (c == 0) {
            for (int a = 0; a < a_count; ++a) if (category[a] == c) label[first[a]] = w;
            continue;
        }
        for (int a = 0; a < a_count; ++a)
            if (category[a] == c && lambda_min(a, first[a]) < w) return 0;
        for (int p = 0; p < N; ++p) if (f_category[p] == c) {
            std::array<int, A> group{}; int count = 0;
            for (int a = 0; a < a_count; ++a) if (category[a] == c && first[a] == p) group[count++] = a;
            if (count == 1) {
                const int earlier = lambda_min(group[0], p);
                label[p] = earlier >= INF ? w : std::min(w, earlier - w);
            } else {
                label[p] = w;
                for (int i = 0; i < count; ++i)
                    if (lambda_min(group[i], p) < 2 * w) keep_first[group[i]] = false;
            }
        }
        for (int a = 0; a < a_count; ++a)
            if (category[a] == c && second[a] >= 0 && lambda_min(a, second[a]) < w) keep_second[a] = false;
    }
    std::array<bool, N> is_first{};
    for (int a = 0; a < a_count; ++a) is_first[first[a]] = true;
    for (int p = 0; p < N; ++p) if (is_first[p]) {
        bool eligible = false;
        for (int a = 0; a < a_count; ++a) if (first[a] == p && keep_first[a]) eligible = true;
        if (!eligible) return 0;
    }
    std::array<std::array<int, 2>, A> edges{};
    std::array<int, A> edge_count{};
    for (int a = 0; a < a_count; ++a) {
        if (keep_first[a]) edges[a][edge_count[a]++] = first[a];
        if (keep_second[a] && second[a] >= 0 && !is_first[second[a]]) edges[a][edge_count[a]++] = second[a];
        if (edge_count[a] == 0) return 0;
    }
    std::array<int, N> owner; owner.fill(-1);
    std::function<bool(int, std::array<bool, N>&)> augment = [&](int a, std::array<bool, N>& seen) {
        for (int i = 0; i < edge_count[a]; ++i) {
            const int p = edges[a][i];
            if (seen[p]) continue;
            seen[p] = true;
            if (owner[p] < 0 || augment(owner[p], seen)) { owner[p] = a; return true; }
        }
        return false;
    };
    for (int a = 0; a < a_count; ++a) { std::array<bool, N> seen{}; if (!augment(a, seen)) return 0; }
    return 1;
}
}

extern "C" std::int64_t mestre_strict_weighted_popular_matching(const std::int64_t* input, std::size_t length) {
    if (input == nullptr || length < 2 || length > PARSEABLE) return -1;
    const auto a64 = input[0], j64 = input[1];
    if (a64 < 1 || a64 > A || j64 < 1 || j64 > J) return -1;
    const int a_count = static_cast<int>(a64), j_count = static_cast<int>(j64);
    if (length < static_cast<std::size_t>(2 + 2 * a_count)) return -1;
    std::array<std::int64_t, A> weight{}; std::array<int, A> list_length{}; int total = 0;
    for (int a = 0; a < a_count; ++a) {
        weight[a] = input[2 + a];
        const auto size = input[2 + a_count + a];
        if (weight[a] < 1 || weight[a] > 1000 || size < 1 || size > j_count) return -1;
        list_length[a] = static_cast<int>(size); total += list_length[a];
    }
    if (length != static_cast<std::size_t>(2 + 2 * a_count + total)) return -1;
    std::array<std::array<int, J>, A> listed{}; std::size_t cursor = 2 + 2 * a_count;
    for (int a = 0; a < a_count; ++a) for (int i = 0; i < list_length[a]; ++i) {
        const auto value = input[cursor++];
        if (value < 0 || value >= j_count) return -1;
        for (int k = 0; k < i; ++k) if (listed[a][k] == value) return -1;
        listed[a][i] = static_cast<int>(value);
    }
    return solve(a_count, j_count, weight, list_length, listed);
}
