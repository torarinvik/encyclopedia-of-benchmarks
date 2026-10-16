module job_scheduling_with_deadline;

const long MAX_PROFIT = 1000000L;
const long PACK_BASE = 4294967296L;

fn long job_scheduling_with_deadline(long* packed, usz length) @export("job_scheduling_with_deadline") {
    if (packed == null || length < 1 || length > 513) return -1;
    long count_value = packed[0];
    if (count_value < 0 || count_value > 128 || length != 1 + (usz)count_value * 4) return -1;
    usz count = (usz)count_value;

    long[128] ids = zeroed;
    long[128] arrivals = zeroed;
    long[128] deadlines = zeroed;
    long[128] profits = zeroed;
    long max_deadline = 0;
    for (usz i = 0; i < count; i++) {
        usz base = 1 + i * 4;
        ids[i] = packed[base];
        arrivals[i] = packed[base + 1];
        deadlines[i] = packed[base + 2];
        profits[i] = packed[base + 3];
        if (ids[i] < 0 || ids[i] > 2147483647L ||
            arrivals[i] < 1 || arrivals[i] > 32 ||
            deadlines[i] < 1 || deadlines[i] > 32 ||
            profits[i] < -MAX_PROFIT || profits[i] > MAX_PROFIT) return -1;
        for (usz previous = 0; previous < i; previous++)
            if (ids[previous] == ids[i]) return -1;
        if (deadlines[i] > max_deadline) max_deadline = deadlines[i];
    }

    // Stable insertion sort keeps input order when profits are equal.
    for (usz i = 1; i < count; i++) {
        long key_id = ids[i];
        long key_arrival = arrivals[i];
        long key_deadline = deadlines[i];
        long key_profit = profits[i];
        usz position = i;
        while (position > 0 && profits[position - 1] < key_profit) {
            ids[position] = ids[position - 1];
            arrivals[position] = arrivals[position - 1];
            deadlines[position] = deadlines[position - 1];
            profits[position] = profits[position - 1];
            position--;
        }
        ids[position] = key_id;
        arrivals[position] = key_arrival;
        deadlines[position] = key_deadline;
        profits[position] = key_profit;
    }

    bool[32] occupied = zeroed;
    long scheduled = 0;
    long total_profit = 0;
    for (usz i = 0; i < count; i++) {
        if (arrivals[i] > deadlines[i]) continue;
        long last_slot = deadlines[i] - 1;
        if (last_slot > max_deadline - 1) last_slot = max_deadline - 1;
        for (long slot = last_slot; slot >= arrivals[i] - 1; slot--) {
            if (!occupied[(usz)slot]) {
                occupied[(usz)slot] = true;
                scheduled++;
                total_profit += profits[i];
                break;
            }
        }
    }
    long low_word = total_profit;
    if (low_word < 0) low_word += PACK_BASE;
    return scheduled * PACK_BASE + low_word;
}
