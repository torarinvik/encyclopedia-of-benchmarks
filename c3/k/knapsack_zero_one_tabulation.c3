module knapsack_zero_one_tabulation;

// Tabulated 0/1 knapsack with one reusable row and portable integer operations.
fn long knapsack_zero_one_tabulation(long* packed, usz length) @export("knapsack_zero_one_tabulation")
{
    if (packed == null || length < 2 || length > 258) return -1;
    if (packed[0] < 0 || packed[0] > 512 || packed[1] < 0 || packed[1] > 128) return -1;
    usz capacity = (usz)packed[0];
    usz item_count = (usz)packed[1];
    if (length != 2 + 2 * item_count) return -1;
    for (usz item = 0; item < item_count; item++) {
        long weight = packed[2 + 2 * item];
        long value = packed[3 + 2 * item];
        if (weight < 1 || weight > 4096 || value < 0 || value > 1000000000) return -1;
    }

    long[513] dp;
    for (usz cap = 0; cap <= capacity; cap++) dp[cap] = 0;
    usz width = capacity + 1;
    usz steps = item_count * width;
    for (usz step = 0; step < steps; step++) {
        usz item = step / width;
        usz current_capacity = capacity - step % width;
        usz weight = (usz)packed[2 + 2 * item];
        long value = packed[3 + 2 * item];
        if (weight <= current_capacity) {
            long candidate = dp[current_capacity - weight] + value;
            if (candidate > dp[current_capacity]) dp[current_capacity] = candidate;
        }
    }
    return dp[capacity];
}
