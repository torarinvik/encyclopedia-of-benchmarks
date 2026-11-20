module brzozowski_dfa_minimization;

fn long brzozowski_dfa_minimization(long* input, usz length) @export("brzozowski_dfa_minimization") {
    if (input == null || length < 3 || length > 10) return -1;
    long n64 = input[0], start64 = input[1], accepting64 = input[2];
    if (n64 < 1 || n64 > 3 || start64 < 0 || start64 >= n64
        || accepting64 < 0 || accepting64 >= (1L << n64)) return -1;
    usz n = (usz)n64;
    if (length != 3 + 2 * n) return -1;
    usz start = (usz)start64;
    long[3][2] transition = {{0}};
    for (usz state = 0; state < n; state++) for (usz symbol = 0; symbol < 2; symbol++) {
        long target = input[3 + 2 * state + symbol];
        if (target < 0 || target >= n64) return -1;
        transition[state][symbol] = target;
    }

    long[8] first_masks = {0};
    usz[8][2] first_delta = {{0}};
    bool[8] first_final = {false};
    int[8] first_id = {-1,-1,-1,-1,-1,-1,-1,-1};
    usz first_count = 1;
    first_masks[0] = accepting64;
    first_id[(usz)accepting64] = 0;
    for (usz cursor = 0; cursor < first_count; cursor++) {
        long subset = first_masks[cursor];
        first_final[cursor] = ((subset >> start) & 1) != 0;
        for (usz symbol = 0; symbol < 2; symbol++) {
            long predecessor = 0;
            for (usz state = 0; state < n; state++)
                if ((subset & (1L << transition[state][symbol])) != 0)
                    predecessor |= 1L << state;
            if (first_id[(usz)predecessor] < 0) {
                first_id[(usz)predecessor] = (int)first_count;
                first_masks[first_count++] = predecessor;
            }
            first_delta[cursor][symbol] = (usz)first_id[(usz)predecessor];
        }
    }

    long first_accepting = 0;
    for (usz state = 0; state < first_count; state++)
        if (first_final[state]) first_accepting |= 1L << state;
    long[256] second_queue = {0};
    bool[256] second_seen = {false};
    usz second_count = 1;
    second_queue[0] = first_accepting;
    second_seen[(usz)first_accepting] = true;
    for (usz cursor = 0; cursor < second_count; cursor++) {
        long subset = second_queue[cursor];
        for (usz symbol = 0; symbol < 2; symbol++) {
            long predecessor = 0;
            for (usz state = 0; state < first_count; state++)
                if ((subset & (1L << first_delta[state][symbol])) != 0)
                    predecessor |= 1L << state;
            if (!second_seen[(usz)predecessor]) {
                second_seen[(usz)predecessor] = true;
                second_queue[second_count++] = predecessor;
            }
        }
    }
    return (long)second_count;
}
