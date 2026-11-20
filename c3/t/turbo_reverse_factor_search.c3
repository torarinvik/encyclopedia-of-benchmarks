module turbo_reverse_factor_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT = 4227;
const usz MAX_STATES = 2 * MAX_PATTERN + 2;
const usz ROOT = 0;
const usz ARTIFICIAL = 1;

struct Automaton {
    long[MAX_STATES * 4] transition;
    long[MAX_STATES * 4] displacement;
    long[MAX_STATES] suffix_link;
    long[MAX_STATES] max_length;
    long[MAX_STATES] position;
    long[MAX_STATES] terminal;
    usz state_count;
}

fn void trf_init(Automaton* aut) {
    aut.state_count = 2;
    for (usz state = 0; state < MAX_STATES; state += 1) {
        aut.suffix_link[state] = -1;
        aut.max_length[state] = 0;
        aut.position[state] = 0;
        aut.terminal[state] = 0;
        for (usz symbol = 0; symbol < 4; symbol += 1) {
            aut.transition[state * 4 + symbol] = -1;
            aut.displacement[state * 4 + symbol] = 0;
        }
    }
    aut.suffix_link[ROOT] = (long)ARTIFICIAL;
}

fn bool trf_build(Automaton* aut, long* pattern, usz m) {
    usz last = ROOT;
    for (usz offset = 0; offset < m; offset += 1) {
        usz symbol = (usz)pattern[m - 1 - offset];
        if (aut.state_count >= MAX_STATES) return false;
        usz current = aut.state_count;
        aut.state_count += 1;
        aut.max_length[current] = aut.max_length[last] + 1;
        aut.position[current] = aut.position[last] + 1;
        long state = (long)last;
        while (state != (long)ROOT && aut.transition[(usz)state * 4 + symbol] < 0) {
            aut.transition[(usz)state * 4 + symbol] = (long)current;
            aut.displacement[(usz)state * 4 + symbol] =
                aut.position[current] - aut.position[(usz)state] - 1;
            state = aut.suffix_link[(usz)state];
        }
        long target = aut.transition[(usz)state * 4 + symbol];
        if (target < 0) {
            aut.transition[ROOT * 4 + symbol] = (long)current;
            aut.displacement[ROOT * 4 + symbol] = aut.position[current] - aut.position[ROOT] - 1;
            aut.suffix_link[current] = (long)ROOT;
        } else if (aut.max_length[(usz)state] + 1 == aut.max_length[(usz)target]) {
            aut.suffix_link[current] = target;
        } else {
            if (aut.state_count >= MAX_STATES) return false;
            usz clone = aut.state_count;
            aut.state_count += 1;
            aut.suffix_link[clone] = aut.suffix_link[(usz)target];
            aut.max_length[clone] = aut.max_length[(usz)state] + 1;
            aut.position[clone] = aut.position[(usz)target];
            aut.terminal[clone] = aut.terminal[(usz)target];
            for (usz c = 0; c < 4; c += 1) {
                aut.transition[clone * 4 + c] = aut.transition[(usz)target * 4 + c];
                aut.displacement[clone * 4 + c] = aut.displacement[(usz)target * 4 + c];
            }
            aut.suffix_link[(usz)target] = (long)clone;
            aut.suffix_link[current] = (long)clone;
            while (state != (long)ARTIFICIAL) {
                long old_target = aut.transition[(usz)state * 4 + symbol];
                if (old_target < 0 || aut.max_length[(usz)old_target] < aut.max_length[clone]) break;
                aut.displacement[(usz)state * 4 + symbol] =
                    aut.position[(usz)old_target] - aut.position[(usz)state] - 1;
                aut.transition[(usz)state * 4 + symbol] = (long)clone;
                state = aut.suffix_link[(usz)state];
            }
        }
        last = current;
    }
    aut.terminal[last] = 1;
    while (last != ROOT) {
        last = (usz)aut.suffix_link[last];
        aut.terminal[last] = 1;
    }
    return true;
}

fn void trf_mp_next(long* pattern, usz m, long* next) {
    long i = 0, border = -1;
    next[0] = -1;
    while ((usz)i < m) {
        while (border >= 0 && pattern[(usz)i] != pattern[(usz)border])
            border = next[(usz)border];
        i += 1;
        border += 1;
        next[(usz)i] = border;
    }
}

fn long trf_search(Automaton* aut, long* input, usz n, usz m, long* mp) {
    if (n < m) return 0;
    long period = (long)m - mp[m];
    long count = 0, offset_sum = 0, offset_xor = 0;
    usz start = 0;
    long preceding_shift = (long)m;
    while (start <= n - m) {
        long index = (long)m - 1;
        usz state = ROOT;
        long boundary = (long)m - 1 - preceding_shift;
        long prefix_length = (long)m - preceding_shift;
        long prefix_period = 0;
        if (preceding_shift != (long)m) prefix_period = prefix_length - mp[(usz)prefix_length];
        long shift = (long)m;
        long displacement_sum = 0;
        while (index > boundary) {
            usz symbol = (usz)input[2 + start + (usz)index];
            long target = aut.transition[state * 4 + symbol];
            if (target < 0) break;
            displacement_sum += aut.displacement[state * 4 + symbol];
            state = (usz)target;
            if (aut.terminal[state] != 0) shift = index;
            index -= 1;
        }
        if (index <= boundary) {
            if (displacement_sum == 0) {
                count += 1;
                offset_sum += (long)start;
                offset_xor ^= (long)start;
                shift = period;
            } else {
                long half = (boundary + 1) / 2;
                if (prefix_period <= half) {
                    boundary -= prefix_period;
                    while (index > boundary) {
                        usz symbol = (usz)input[2 + start + (usz)index];
                        long target = aut.transition[state * 4 + symbol];
                        if (target < 0) break;
                        displacement_sum += aut.displacement[state * 4 + symbol];
                        state = (usz)target;
                        if (aut.terminal[state] != 0) shift = index;
                        index -= 1;
                    }
                    if (index <= boundary) shift = displacement_sum;
                } else {
                    boundary = boundary - half - 1;
                    while (index > boundary) {
                        usz symbol = (usz)input[2 + start + (usz)index];
                        long target = aut.transition[state * 4 + symbol];
                        if (target < 0) break;
                        displacement_sum += aut.displacement[state * 4 + symbol];
                        state = (usz)target;
                        if (aut.terminal[state] != 0) shift = index;
                        index -= 1;
                    }
                }
            }
        }
        if (shift <= 0) return -1;
        start += (usz)shift;
        preceding_shift = shift;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

fn long turbo_reverse_factor_search(long* input, usz length) @export("turbo_reverse_factor_search") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long nv = input[0], mv = input[1];
    if (nv < 0 || nv > (long)MAX_TEXT || mv < 1 || mv > (long)MAX_PATTERN) return -1;
    usz n = (usz)nv, m = (usz)mv;
    if (length != 2 + n + m) return -1;
    for (usz i = 0; i < n + m; i += 1)
        if (input[2 + i] < 0 || input[2 + i] > 3) return -1;
    long[MAX_PATTERN] pattern = zeroed;
    for (usz i = 0; i < m; i += 1) pattern[i] = input[2 + n + i];
    Automaton aut;
    trf_init(&aut);
    if (!trf_build(&aut, &pattern[0], m)) return -1;
    long[MAX_PATTERN + 1] mp = zeroed;
    trf_mp_next(&pattern[0], m, &mp[0]);
    return trf_search(&aut, input, n, m, &mp[0]);
}
