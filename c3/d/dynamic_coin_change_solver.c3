module dynamic_coin_change_solver;

fn long dynamic_coin_change_solver(long* input, usz length) @export("dynamic_coin_change_solver") {
    if (input == null || length < 3 || length > 11) return -1;
    long amount = input[0];
    long count = input[1];
    if (amount < 1 || amount > 18 || count < 1 || count > 9 || length != (usz)(count + 2)) return -1;
    long[9] coins;
    bool has_one = false;
    for (int i = 0; i < (int)count; i++) {
        if (input[i + 2] < 1 || input[i + 2] > 9) return -1;
        coins[i] = input[i + 2];
        if (coins[i] == 1) has_one = true;
        for (int j = 0; j < i; j++) if (coins[i] == coins[j]) return -1;
    }
    if (!has_one) return -1;
    for (int i = 0; i < (int)count; i++) {
        for (int j = i + 1; j < (int)count; j++) {
            if (coins[i] < coins[j]) { long temp = coins[i]; coins[i] = coins[j]; coins[j] = temp; }
        }
    }
    long[19 * 9] changes;
    int[19] sizes;
    for (int i = 0; i < 171; i++) changes[i] = 0;
    for (int i = 0; i < 19; i++) sizes[i] = 0;
    for (int value = 1; value <= (int)amount; value++) {
        for (int i = 0; i < (int)count; i++) {
            if (coins[i] <= value) { changes[value * 9 + sizes[value]] = (long)value - coins[i]; sizes[value]++; }
        }
    }
    long current = amount;
    long code = 0;
    for (int step = 0; step < 18; step++) {
        long next = 2147483647;
        long min_change = 2147483647;
        for (int i = 0; i < sizes[(int)current]; i++) {
            long change = changes[(int)current * 9 + i];
            if (change == 0) { next = 0; break; }
            long minimum = 2147483647;
            for (int j = 0; j < sizes[(int)change]; j++) if (changes[(int)change * 9 + j] < minimum) minimum = changes[(int)change * 9 + j];
            if (minimum < min_change) { min_change = minimum; next = change; }
        }
        if (next == 2147483647) return -1;
        code = code * 10 + current - next;
        if (next == 0) return code;
        current = next;
    }
    return -1;
}
