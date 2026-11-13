module bounded_knapsack_monotone_queue;

// Bounded knapsack by residue-class sliding maxima.
fn long bounded_knapsack_monotone_queue(long* packed, usz length) @export("bounded_knapsack_monotone_queue")
{
    if (packed == null || length < 2 || length > 51) return -1;
    if (packed[0] < 0 || packed[0] > 64 || packed[1] < 0 || packed[1] > 16) return -1;
    usz capacity = (usz)packed[0];
    usz types = (usz)packed[1];
    if (length != 2 + 3 * types) return -1;
    for (usz item = 0; item < types; item++) {
        long weight = packed[2 + 3 * item];
        long value = packed[3 + 3 * item];
        long count = packed[4 + 3 * item];
        if (weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16) return -1;
    }

    long[65] dp;
    long[65] next;
    long[65] queue_score;
    usz[65] queue_index;
    for (usz c = 0; c <= capacity; c++) { dp[c] = 0; next[c] = 0; }
    for (usz item = 0; item < types; item++) {
        usz weight = (usz)packed[2 + 3 * item];
        long value = packed[3 + 3 * item];
        usz count = (usz)packed[4 + 3 * item];
        for (usz residue = 0; residue < weight && residue <= capacity; residue++) {
            usz head = 0;
            usz tail = 0;
            usz max_t = (capacity - residue) / weight;
            for (usz t = 0; t <= max_t; t++) {
                usz current = residue + t * weight;
                long score = dp[current] - (long)t * value;
                while (tail > head && queue_score[tail - 1] <= score) tail--;
                queue_index[tail] = t;
                queue_score[tail] = score;
                tail++;
                usz first_allowed = t > count ? t - count : 0;
                while (head < tail && queue_index[head] < first_allowed) head++;
                next[current] = (long)t * value + queue_score[head];
            }
        }
        for (usz c = 0; c <= capacity; c++) dp[c] = next[c];
    }
    return dp[capacity];
}
