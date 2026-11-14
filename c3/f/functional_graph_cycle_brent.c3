module functional_graph_cycle_brent;

fn long functional_graph_cycle_brent(long* input, usz length) @export("functional_graph_cycle_brent") {
    if (input == null || length < 3 || length > 67) return -1;
    long n = input[0], start = input[1];
    if (n < 1 || n > 64 || start < 0 || start >= n || length != (n + 2).usz()) return -1;
    for (long i = 0; i < n; i++) if (input[2+i] < 0 || input[2+i] >= n) return -1;
    long checkpoint = start, moving = input[2+start], power = 1, period = 1;
    while (checkpoint != moving) {
        if (power == period) { checkpoint = moving; power *= 2; period = 0; }
        moving = input[2+moving]; period++;
    }
    long left = start, right = start;
    for (long i = 0; i < period; i++) right = input[2+right];
    long tail = 0;
    while (left != right) { left = input[2+left]; right = input[2+right]; tail++; }
    return 65 * tail + period;
}
