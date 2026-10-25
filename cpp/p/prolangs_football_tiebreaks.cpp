#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t kMaxGames = 64;
constexpr std::int64_t kMaxNet = 4096;
struct Fraction { std::int64_t numerator; std::int64_t denominator; };
using Group = std::vector<int>;

bool same_division(const std::int64_t *v, const Group &group) {
    const std::size_t first = 1 + 12 * static_cast<std::size_t>(group[0]);
    for (std::size_t i = 1; i < group.size(); ++i) {
        const std::size_t current = 1 + 12 * static_cast<std::size_t>(group[i]);
        if (v[first + 1] != v[current + 1] || v[first + 2] != v[current + 2]) return false;
    }
    return true;
}

Fraction score_for(const std::int64_t *v, int n, const Group &group, int team,
                  int stage, bool same_div) {
    Fraction score{0, 1};
    if (stage == 0) {
        const std::size_t cells = static_cast<std::size_t>(n) * n;
        const std::size_t wins_start = 1 + 12 * static_cast<std::size_t>(n);
        const std::size_t ties_start = wins_start + cells;
        std::int64_t won = 0, lost = 0, tied = 0;
        for (int other : group) {
            if (other == team) continue;
            won += v[wins_start + static_cast<std::size_t>(team) * n + other];
            lost += v[wins_start + static_cast<std::size_t>(other) * n + team];
            tied += v[ties_start + static_cast<std::size_t>(team) * n + other];
        }
        const auto games = won + lost + tied;
        return {2 * won + tied, games == 0 ? 1 : 2 * games};
    }
    const std::size_t base = 1 + 12 * static_cast<std::size_t>(team);
    if (stage >= 1 && stage <= 3) {
        const std::size_t points_field = stage == 1 ? 3 : (stage == 2 ? 5 : 7);
        const std::size_t games_field = points_field + 1;
        const auto games = v[base + games_field];
        return {v[base + points_field], games == 0 ? 1 : 2 * games};
    }
    if (stage == 4) return {v[base + (same_div ? 9 : 10)], 1};
    return {v[base + 11], 1};
}

int compare(Fraction a, Fraction b) {
    const auto left = a.numerator * b.denominator;
    const auto right = b.numerator * a.denominator;
    return (left > right) - (left < right);
}

void resolve(const std::int64_t *, int, Group &, int);

void split_by_score(const std::int64_t *v, int n, Group &group, int stage, bool same_div) {
    std::stable_sort(group.begin(), group.end(), [&](int a, int b) {
        return compare(score_for(v, n, group, a, stage, same_div),
                       score_for(v, n, group, b, stage, same_div)) > 0;
    });
    bool split = false;
    const auto best = score_for(v, n, group, group[0], stage, same_div);
    for (std::size_t i = 1; i < group.size(); ++i)
        if (compare(best, score_for(v, n, group, group[i], stage, same_div)) != 0) split = true;
    if (!split) { resolve(v, n, group, stage + 1); return; }
    std::size_t start = 0;
    while (start < group.size()) {
        std::size_t end = start + 1;
        const auto score = score_for(v, n, group, group[start], stage, same_div);
        while (end < group.size() && compare(score, score_for(v, n, group, group[end], stage, same_div)) == 0) ++end;
        Group part(group.begin() + static_cast<std::ptrdiff_t>(start),
                   group.begin() + static_cast<std::ptrdiff_t>(end));
        resolve(v, n, part, 0);
        std::copy(part.begin(), part.end(), group.begin() + static_cast<std::ptrdiff_t>(start));
        start = end;
    }
}

int sweep_result(const std::int64_t *v, int n, const Group &group) {
    const std::size_t cells = static_cast<std::size_t>(n) * n;
    const std::size_t wins_start = 1 + 12 * static_cast<std::size_t>(n);
    const std::size_t ties_start = wins_start + cells;
    for (std::size_t position = 0; position < group.size(); ++position) {
        const int team = group[position];
        bool win = true, lose = true;
        for (int other : group) {
            if (other == team) continue;
            const auto won = v[wins_start + static_cast<std::size_t>(team) * n + other];
            const auto lost = v[wins_start + static_cast<std::size_t>(other) * n + team];
            const auto tied = v[ties_start + static_cast<std::size_t>(team) * n + other];
            if (won + lost + tied == 0 || tied != 0) win = lose = false;
            if (lost != 0) win = false;
            if (won != 0) lose = false;
        }
        if (win) return static_cast<int>(position) + 1;
        if (lose) return -(static_cast<int>(position) + 1);
    }
    return 0;
}

void resolve(const std::int64_t *v, int n, Group &group, int stage) {
    if (group.size() <= 1 || stage >= 6) return;
    const bool same_div = same_division(v, group);
    if (stage == 0) {
        if (same_div || group.size() == 2) { split_by_score(v, n, group, 0, same_div); return; }
        const int sweep = sweep_result(v, n, group);
        if (sweep > 0) {
            std::swap(group[0], group[static_cast<std::size_t>(sweep - 1)]);
            Group rest(group.begin() + 1, group.end()); resolve(v, n, rest, 0);
            std::copy(rest.begin(), rest.end(), group.begin() + 1); return;
        }
        if (sweep < 0) {
            const std::size_t position = static_cast<std::size_t>(-sweep - 1);
            std::swap(group.back(), group[position]);
            Group rest(group.begin(), group.end() - 1); resolve(v, n, rest, 0);
            std::copy(rest.begin(), rest.end(), group.begin()); return;
        }
        resolve(v, n, group, 1); return;
    }
    if (stage == 1 && !same_div) { resolve(v, n, group, 2); return; }
    if (stage == 3) {
        for (int i : group) if (v[1 + 12 * static_cast<std::size_t>(i) + 8] < 4) {
            resolve(v, n, group, 4); return;
        }
    }
    split_by_score(v, n, group, stage, same_div);
}
} // namespace

extern "C" std::int64_t prolangs_football_tiebreaks(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || values[0] < 2 || values[0] > 8) return -2;
    const int n = static_cast<int>(values[0]);
    const std::size_t cells = static_cast<std::size_t>(n) * n;
    if (length != 1 + 12 * static_cast<std::size_t>(n) + 2 * cells) return -2;
    Group order;
    for (int i = 0; i < n; ++i) {
        const std::size_t base = 1 + 12 * static_cast<std::size_t>(i);
        const auto id = values[base];
        if (id < 0 || id > 31 || values[base + 1] < 0 || values[base + 1] > 1 ||
            values[base + 2] < 0 || values[base + 2] > 2) return -2;
        for (int f = 3; f <= 8; f += 2) {
            const auto points = values[base + static_cast<std::size_t>(f)];
            const auto games = values[base + static_cast<std::size_t>(f + 1)];
            if (games < 0 || games > kMaxGames || points < 0 || points > 2 * games) return -2;
        }
        for (int f = 9; f <= 11; ++f)
            if (values[base + static_cast<std::size_t>(f)] < -kMaxNet || values[base + static_cast<std::size_t>(f)] > kMaxNet) return -2;
        for (int prior = 0; prior < i; ++prior)
            if (values[1 + 12 * static_cast<std::size_t>(prior)] == id) return -2;
        order.push_back(i);
    }
    const std::size_t wins_start = 1 + 12 * static_cast<std::size_t>(n);
    const std::size_t ties_start = wins_start + cells;
    for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j) {
        const auto wins = values[wins_start + static_cast<std::size_t>(i) * n + j];
        const auto ties = values[ties_start + static_cast<std::size_t>(i) * n + j];
        if (wins < 0 || wins > kMaxGames || ties < 0 || ties > kMaxGames ||
            (i == j && (wins != 0 || ties != 0)) ||
            ties != values[ties_start + static_cast<std::size_t>(j) * n + i]) return -2;
    }
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
        const std::size_t a_base = 1 + 12 * static_cast<std::size_t>(a);
        const std::size_t b_base = 1 + 12 * static_cast<std::size_t>(b);
        if (values[a_base + 1] != values[b_base + 1]) return values[a_base + 1] < values[b_base + 1];
        return values[a_base] < values[b_base];
    });
    resolve(values, n, order, 0);
    std::int64_t result = 0;
    for (int i : order) result = result * 32 + values[1 + 12 * static_cast<std::size_t>(i)];
    return result;
}
