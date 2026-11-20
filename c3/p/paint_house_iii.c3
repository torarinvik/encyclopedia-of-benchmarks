module paint_house_iii;

const usz MAX_INPUT = 44;
const long INF = 801;

fn usz state(usz color, usz groups) { return color * 9 + groups; }

fn long paint_house_iii(long *input, usz length) @export("paint_house_iii") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long m_value = input[0], n_value = input[1], target_value = input[2];
    if (m_value < 1 || m_value > 8 || n_value < 1 || n_value > 4 ||
        target_value < 1 || target_value > m_value) return -1;
    usz m = (usz)m_value, n = (usz)n_value, target = (usz)target_value;
    if (length != (usz)3 + m + m * n) return -1;
    usz houses_at = 3, costs_at = 3 + m;
    for (usz i = 0; i < m; i++)
        if (input[houses_at + i] < 0 || input[houses_at + i] > n_value) return -1;
    for (usz i = 0; i < m * n; i++)
        if (input[costs_at + i] < 0 || input[costs_at + i] > 100) return -1;

    long[45] previous, current;
    for (usz i = 0; i < 45; i++) previous[i] = INF;
    long first = input[houses_at];
    for (usz color = 1; color <= n; color++)
        if (first == 0 || first == (long)color)
            previous[state(color, 1)] = first == 0 ? input[costs_at + color - 1] : 0;

    for (usz house = 1; house < m; house++) {
        for (usz i = 0; i < 45; i++) current[i] = INF;
        long fixed = input[houses_at + house];
        for (usz color = 1; color <= n; color++) {
            if (fixed != 0 && fixed != (long)color) continue;
            long paint_cost = fixed == 0 ? input[costs_at + house * n + color - 1] : 0;
            for (usz groups = 1; groups <= target; groups++) {
                long best = INF;
                for (usz old_color = 1; old_color <= n; old_color++) {
                    usz old_groups = groups - (old_color != color ? 1 : 0);
                    if (old_groups >= 1 && previous[state(old_color, old_groups)] < best)
                        best = previous[state(old_color, old_groups)];
                }
                if (best < INF) current[state(color, groups)] = best + paint_cost;
            }
        }
        for (usz i = 0; i < 45; i++) previous[i] = current[i];
    }
    long answer = INF;
    for (usz color = 1; color <= n; color++)
        if (previous[state(color, target)] < answer) answer = previous[state(color, target)];
    return answer >= INF ? -1 : answer;
}
