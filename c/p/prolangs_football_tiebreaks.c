#include <stddef.h>
#include <stdint.h>

#define MAX_TEAMS 8
#define MAX_GAMES 64
#define MAX_NET 4096

typedef struct { int64_t numerator, denominator; } Fraction;

static int same_division(const int64_t *v, int n, const int *ids, int count) {
    const size_t first = 1u + 12u * (size_t)ids[0];
    for (int i = 1; i < count; ++i) {
        const size_t current = 1u + 12u * (size_t)ids[i];
        if (v[first + 1] != v[current + 1] || v[first + 2] != v[current + 2]) return 0;
    }
    (void)n;
    return 1;
}

static Fraction score_for(const int64_t *v, int n, const int *ids, int count,
                          int team, int stage, int same_div) {
    Fraction score = {0, 1};
    if (stage == 0) {
        const size_t cells = (size_t)n * (size_t)n;
        const size_t wins_start = 1u + 12u * (size_t)n;
        const size_t ties_start = wins_start + cells;
        int64_t won = 0, lost = 0, tied = 0;
        for (int i = 0; i < count; ++i) {
            const int other = ids[i];
            if (other == team) continue;
            won += v[wins_start + (size_t)team * (size_t)n + (size_t)other];
            lost += v[wins_start + (size_t)other * (size_t)n + (size_t)team];
            tied += v[ties_start + (size_t)team * (size_t)n + (size_t)other];
        }
        const int64_t games = won + lost + tied;
        score.numerator = 2 * won + tied;
        score.denominator = games == 0 ? 1 : 2 * games;
        return score;
    }

    const size_t base = 1u + 12u * (size_t)team;
    if (stage == 1) {
        score.numerator = v[base + 3];
        score.denominator = v[base + 4] == 0 ? 1 : 2 * v[base + 4];
    } else if (stage == 2) {
        score.numerator = v[base + 5];
        score.denominator = v[base + 6] == 0 ? 1 : 2 * v[base + 6];
    } else if (stage == 3) {
        score.numerator = v[base + 7];
        score.denominator = v[base + 8] == 0 ? 1 : 2 * v[base + 8];
    } else if (stage == 4) {
        score.numerator = v[base + (same_div ? 9 : 10)];
    } else {
        score.numerator = v[base + 11];
    }
    return score;
}

static int compare_score(Fraction left, Fraction right) {
    const int64_t a = left.numerator * right.denominator;
    const int64_t b = right.numerator * left.denominator;
    return (a > b) - (a < b);
}

static void resolve(const int64_t *v, int n, int *ids, int count, int stage);

static void score_split(const int64_t *v, int n, int *ids, int count,
                        int stage, int same_div) {
    for (int i = 1; i < count; ++i) {
        const int item = ids[i];
        const Fraction item_score = score_for(v, n, ids, count, item, stage, same_div);
        int j = i;
        while (j > 0) {
            const Fraction previous = score_for(v, n, ids, count, ids[j - 1], stage, same_div);
            if (compare_score(item_score, previous) <= 0) break;
            ids[j] = ids[j - 1];
            --j;
        }
        ids[j] = item;
    }

    int has_split = 0;
    const Fraction best = score_for(v, n, ids, count, ids[0], stage, same_div);
    for (int i = 1; i < count; ++i) {
        if (compare_score(best, score_for(v, n, ids, count, ids[i], stage, same_div)) != 0) {
            has_split = 1;
            break;
        }
    }
    if (!has_split) {
        resolve(v, n, ids, count, stage + 1);
        return;
    }

    int start = 0;
    while (start < count) {
        int end = start + 1;
        const Fraction group_score = score_for(v, n, ids, count, ids[start], stage, same_div);
        while (end < count && compare_score(group_score,
               score_for(v, n, ids, count, ids[end], stage, same_div)) == 0) ++end;
        resolve(v, n, ids + start, end - start, 0);
        start = end;
    }
}

static int sweep_result(const int64_t *v, int n, const int *ids, int count) {
    const size_t cells = (size_t)n * (size_t)n;
    const size_t wins_start = 1u + 12u * (size_t)n;
    const size_t ties_start = wins_start + cells;
    for (int position = 0; position < count; ++position) {
        const int team = ids[position];
        int sweeps_win = 1, sweeps_lose = 1;
        for (int j = 0; j < count; ++j) {
            const int other = ids[j];
            if (other == team) continue;
            const int64_t won = v[wins_start + (size_t)team * (size_t)n + (size_t)other];
            const int64_t lost = v[wins_start + (size_t)other * (size_t)n + (size_t)team];
            const int64_t tied = v[ties_start + (size_t)team * (size_t)n + (size_t)other];
            if (won + lost + tied == 0 || tied != 0) sweeps_win = sweeps_lose = 0;
            if (lost != 0) sweeps_win = 0;
            if (won != 0) sweeps_lose = 0;
        }
        if (sweeps_win) return position + 1;
        if (sweeps_lose) return -(position + 1);
    }
    return 0;
}

static void resolve(const int64_t *v, int n, int *ids, int count, int stage) {
    if (count <= 1 || stage >= 6) return;
    const int same_div = same_division(v, n, ids, count);
    if (stage == 0) {
        if (same_div || count == 2) {
            score_split(v, n, ids, count, 0, same_div);
            return;
        }
        const int sweep = sweep_result(v, n, ids, count);
        if (sweep > 0) {
            const int position = sweep - 1;
            const int first = ids[0]; ids[0] = ids[position]; ids[position] = first;
            resolve(v, n, ids + 1, count - 1, 0);
            return;
        }
        if (sweep < 0) {
            const int position = -sweep - 1;
            const int last = ids[count - 1]; ids[count - 1] = ids[position]; ids[position] = last;
            resolve(v, n, ids, count - 1, 0);
            return;
        }
        resolve(v, n, ids, count, 1);
        return;
    }
    if (stage == 1 && !same_div) { resolve(v, n, ids, count, 2); return; }
    if (stage == 3) {
        for (int i = 0; i < count; ++i)
            if (v[1u + 12u * (size_t)ids[i] + 8] < 4) {
                resolve(v, n, ids, count, 4);
                return;
            }
    }
    score_split(v, n, ids, count, stage, same_div);
}

int64_t prolangs_football_tiebreaks(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || values[0] < 2 || values[0] > MAX_TEAMS) return -2;
    const int n = (int)values[0];
    const size_t cells = (size_t)n * (size_t)n;
    if (length != 1u + 12u * (size_t)n + 2u * cells) return -2;
    int ids[MAX_TEAMS];
    for (int i = 0; i < n; ++i) {
        const size_t base = 1u + 12u * (size_t)i;
        const int64_t id = values[base], conference = values[base + 1], division = values[base + 2];
        if (id < 0 || id > 31 || conference < 0 || conference > 1 || division < 0 || division > 2)
            return -2;
        ids[i] = i;
        for (int field = 3; field <= 8; field += 2) {
            const int64_t points = values[base + (size_t)field];
            const int64_t games = values[base + (size_t)field + 1];
            if (games < 0 || games > MAX_GAMES || points < 0 || points > 2 * games) return -2;
        }
        for (int field = 9; field <= 11; ++field)
            if (values[base + (size_t)field] < -MAX_NET || values[base + (size_t)field] > MAX_NET) return -2;
        for (int previous = 0; previous < i; ++previous)
            if (values[1u + 12u * (size_t)previous] == id) return -2;
    }
    const size_t wins_start = 1u + 12u * (size_t)n;
    const size_t ties_start = wins_start + cells;
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            const int64_t wins = values[wins_start + (size_t)i * (size_t)n + (size_t)j];
            const int64_t ties = values[ties_start + (size_t)i * (size_t)n + (size_t)j];
            if (wins < 0 || wins > MAX_GAMES || ties < 0 || ties > MAX_GAMES) return -2;
            if ((i == j && (wins != 0 || ties != 0)) ||
                ties != values[ties_start + (size_t)j * (size_t)n + (size_t)i]) return -2;
        }
    }
    for (int i = 1; i < n; ++i) {
        const int item = ids[i];
        int j = i;
        size_t previous_base = 1u + 12u * (size_t)ids[j - 1];
        const size_t item_base = 1u + 12u * (size_t)item;
        while (j > 0 && (values[previous_base + 1] > values[item_base + 1] ||
               (values[previous_base + 1] == values[item_base + 1] && values[previous_base] > values[item_base]))) {
            ids[j] = ids[j - 1]; --j;
            if (j > 0) previous_base = 1u + 12u * (size_t)ids[j - 1];
        }
        ids[j] = item;
    }
    resolve(values, n, ids, n, 0);
    int64_t result = 0;
    for (int i = 0; i < n; ++i) result = result * 32 + values[1u + 12u * (size_t)ids[i]];
    return result;
}
