module prolangs_football_tiebreaks;

const int MAX_TEAMS = 8;
const long MAX_GAMES = 64;
const long MAX_NET = 4096;
struct Fraction { long numerator; long denominator; }
struct Group { int lo; int hi; int stage; }

fn bool same_division(long* v, int* ids, int lo, int hi) {
    long first = 1 + 12 * ids[lo];
    for (int p = lo + 1; p < hi; p++) {
        long current = 1 + 12 * ids[p];
        if (v[first + 1] != v[current + 1] || v[first + 2] != v[current + 2]) return false;
    }
    return true;
}

fn Fraction score_for(long* v, int n, int* ids, int lo, int hi, int team, int stage, bool same_div) {
    Fraction score = {0, 1};
    if (stage == 0) {
        int cells = n * n;
        int wins_start = 1 + 12 * n;
        int ties_start = wins_start + cells;
        long won = 0, lost = 0, tied = 0;
        for (int p = lo; p < hi; p++) {
            int other = ids[p];
            if (other == team) continue;
            won += v[wins_start + team * n + other];
            lost += v[wins_start + other * n + team];
            tied += v[ties_start + team * n + other];
        }
        long games = won + lost + tied;
        score.numerator = 2 * won + tied;
        score.denominator = games == 0 ? 1 : 2 * games;
        return score;
    }
    int base = 1 + 12 * team;
    if (stage >= 1 && stage <= 3) {
        int field = stage == 1 ? 3 : (stage == 2 ? 5 : 7);
        long games = v[base + field + 1];
        score.numerator = v[base + field];
        score.denominator = games == 0 ? 1 : 2 * games;
    } else if (stage == 4) {
        score.numerator = v[base + (same_div ? 9 : 10)];
    } else score.numerator = v[base + 11];
    return score;
}

fn int compare_score(Fraction a, Fraction b) {
    long left = a.numerator * b.denominator;
    long right = b.numerator * a.denominator;
    return (left > right) - (left < right);
}

fn void refine(long* v, int n, int* ids, int lo, int hi, int stage, bool same_div,
               Group* out, int* out_count) {
    for (int i = lo + 1; i < hi; i++) {
        int item = ids[i];
        Fraction item_score = score_for(v, n, ids, lo, hi, item, stage, same_div);
        int j = i;
        while (j > lo) {
            Fraction previous = score_for(v, n, ids, lo, hi, ids[j - 1], stage, same_div);
            if (compare_score(item_score, previous) <= 0) break;
            ids[j] = ids[j - 1]; j--;
        }
        ids[j] = item;
    }
    Fraction best = score_for(v, n, ids, lo, hi, ids[lo], stage, same_div);
    bool split = false;
    for (int i = lo + 1; i < hi; i++)
        if (compare_score(best, score_for(v, n, ids, lo, hi, ids[i], stage, same_div)) != 0) split = true;
    if (!split) { out[*out_count] = {lo, hi, stage + 1}; *out_count += 1; return; }
    int start = lo;
    while (start < hi) {
        Fraction value = score_for(v, n, ids, lo, hi, ids[start], stage, same_div);
        int end = start + 1;
        while (end < hi && compare_score(value, score_for(v, n, ids, lo, hi, ids[end], stage, same_div)) == 0) end++;
        out[*out_count] = {start, end, 0}; *out_count += 1;
        start = end;
    }
}

fn int sweep_result(long* v, int n, int* ids, int lo, int hi) {
    int cells = n * n;
    int wins_start = 1 + 12 * n;
    int ties_start = wins_start + cells;
    for (int position = 0; position < hi - lo; position++) {
        int team = ids[lo + position]; bool win = true, lose = true;
        for (int j = lo; j < hi; j++) {
            int other = ids[j]; if (other == team) continue;
            long won = v[wins_start + team * n + other];
            long lost = v[wins_start + other * n + team];
            long tied = v[ties_start + team * n + other];
            if (won + lost + tied == 0 || tied != 0) { win = false; lose = false; }
            if (lost != 0) win = false;
            if (won != 0) lose = false;
        }
        if (win) return position + 1;
        if (lose) return -(position + 1);
    }
    return 0;
}

fn long prolangs_football_tiebreaks(long* values, usz length) @export("prolangs_football_tiebreaks") {
    if (values == null || length < 1 || values[0] < 2 || values[0] > MAX_TEAMS) return -2;
    int n = (int)values[0], cells = (int)values[0] * (int)values[0];
    if (length != 1 + 12 * n + 2 * cells) return -2;
    int ids[MAX_TEAMS];
    for (int i = 0; i < n; i++) {
        int base = 1 + 12 * i;
        if (values[base] < 0 || values[base] > 31 || values[base + 1] < 0 || values[base + 1] > 1 ||
            values[base + 2] < 0 || values[base + 2] > 2) return -2;
        for (int f = 3; f <= 8; f += 2) {
            long points = values[base + f], games = values[base + f + 1];
            if (games < 0 || games > MAX_GAMES || points < 0 || points > 2 * games) return -2;
        }
        for (int f = 9; f <= 11; f++) if (values[base + f] < -MAX_NET || values[base + f] > MAX_NET) return -2;
        for (int j = 0; j < i; j++) if (values[1 + 12 * j] == values[base]) return -2;
        ids[i] = i;
    }
    int wins_start = 1 + 12 * n, ties_start = wins_start + cells;
    for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) {
        long wins = values[wins_start + i * n + j], ties = values[ties_start + i * n + j];
        if (wins < 0 || wins > MAX_GAMES || ties < 0 || ties > MAX_GAMES ||
            (i == j && (wins != 0 || ties != 0)) || ties != values[ties_start + j * n + i]) return -2;
    }
    for (int i = 1; i < n; i++) {
        int item = ids[i], j = i;
        while (j > 0 && (values[1 + 12 * ids[j - 1] + 1] > values[1 + 12 * item + 1] ||
               (values[1 + 12 * ids[j - 1] + 1] == values[1 + 12 * item + 1] && values[1 + 12 * ids[j - 1]] > values[1 + 12 * item]))) { ids[j] = ids[j - 1]; j--; }
        ids[j] = item;
    }
    Group groups[MAX_TEAMS], next[MAX_TEAMS]; int group_count = 1;
    groups[0] = {0, n, 0};
    while (true) {
        int next_count = 0; bool active = false;
        for (int g = 0; g < group_count; g++) {
            int lo = groups[g].lo, hi = groups[g].hi, stage = groups[g].stage;
            if (hi - lo <= 1 || stage >= 6) { next[next_count++] = {lo, hi, 6}; continue; }
            active = true;
            bool same_div = same_division(values, ids, lo, hi);
            if (stage == 0) {
                if (same_div || hi - lo == 2) {
                    refine(values, n, ids, lo, hi, 0, same_div, next, &next_count);
                } else {
                    int sweep = sweep_result(values, n, ids, lo, hi);
                    if (sweep > 0) {
                        int p = lo + sweep - 1, tmp = ids[lo]; ids[lo] = ids[p]; ids[p] = tmp;
                        next[next_count++] = {lo, lo + 1, 0}; next[next_count++] = {lo + 1, hi, 0};
                    } else if (sweep < 0) {
                        int p = lo - sweep - 1, tmp = ids[hi - 1]; ids[hi - 1] = ids[p]; ids[p] = tmp;
                        next[next_count++] = {lo, hi - 1, 0}; next[next_count++] = {hi - 1, hi, 0};
                    } else next[next_count++] = {lo, hi, 1};
                }
            } else if (stage == 1 && !same_div) next[next_count++] = {lo, hi, 2};
            else if (stage == 3) {
                bool skip_common = false;
                for (int p = lo; p < hi; p++) if (values[1 + 12 * ids[p] + 8] < 4) skip_common = true;
                if (skip_common) next[next_count++] = {lo, hi, 4};
                else refine(values, n, ids, lo, hi, stage, same_div, next, &next_count);
            } else refine(values, n, ids, lo, hi, stage, same_div, next, &next_count);
        }
        for (int i = 0; i < next_count; i++) groups[i] = next[i];
        group_count = next_count;
        if (!active) break;
    }
    long result = 0;
    for (int i = 0; i < n; i++) result = result * 32 + values[1 + 12 * ids[i]];
    return result;
}
