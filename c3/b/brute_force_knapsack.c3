module brute_force_knapsack;

fn long solve(long* packed, usz item_count, long capacity) {
    if (item_count == 0 || capacity == 0) return 0;
    long weight = packed[2 + 2 * (item_count - 1)];
    long value = packed[3 + 2 * (item_count - 1)];
    if (weight > capacity) return solve(packed, item_count - 1, capacity);
    long excluded = solve(packed, item_count - 1, capacity);
    long included = value + solve(packed, item_count - 1, capacity - weight);
    return excluded > included ? excluded : included;
}

fn long brute_force_knapsack(long* packed, usz length) @export("brute_force_knapsack") {
    if (packed == null || length < 2 || length > 30) return -1;
    long capacity = packed[0];
    long count_value = packed[1];
    if (capacity < 0 || capacity > 512 || count_value < 0 || count_value > 14) return -1;
    usz item_count = (usz)count_value;
    if (length != 2 + 2 * item_count) return -1;
    for (usz item = 0; item < item_count; item++) {
        long weight = packed[2 + 2 * item];
        long value = packed[3 + 2 * item];
        if (weight < 1 || weight > 4096 || value < 0 || value > 100000000) return -1;
    }
    return solve(packed, item_count, capacity);
}
