module knapsack_recursive_01;

const long MAX_CAPACITY = 512;
const long MAX_ITEMS = 16;
const long MAX_WEIGHT = 4096;
const long MAX_VALUE = 1000000000;

fn long solve(long* packed, long item_count, long capacity) {
    if (item_count == 0 || capacity == 0) return 0;
    usz offset = 2 + 2 * (usz)(item_count - 1);
    long weight = packed[offset];
    long value = packed[offset + 1];
    if (weight <= capacity) {
        long take = value + solve(packed, item_count - 1, capacity - weight);
        long skip = solve(packed, item_count - 1, capacity);
        return take > skip ? take : skip;
    }
    return solve(packed, item_count - 1, capacity);
}

fn long knapsack_01_recursive_benchmark(long* packed, usz length) @export("knapsack_01_recursive_benchmark") {
    if (length < 2 || length > 2 + 2 * (usz)MAX_ITEMS) return -1;
    long capacity = packed[0];
    long item_count = packed[1];
    if (capacity < 0 || capacity > MAX_CAPACITY || item_count < 0 || item_count > MAX_ITEMS
        || length != 2 + 2 * (usz)item_count) return -1;
    for (usz item = 0; item < (usz)item_count; item++) {
        usz offset = 2 + 2 * item;
        if (packed[offset] < 1 || packed[offset] > MAX_WEIGHT
            || packed[offset + 1] < 0 || packed[offset + 1] > MAX_VALUE) return -1;
    }
    return solve(packed, item_count, capacity);
}
