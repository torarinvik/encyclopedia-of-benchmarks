module bounded_knapsack_binary_grouping;

const long MAX_TYPES = 16;
const long MAX_CAPACITY = 64;
const usz MAX_INPUT = 51;

fn long bounded_knapsack_binary_grouping(long* input, usz length) @export("bounded_knapsack_binary_grouping") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], capacity_value = input[1];
    if (n_value < 0 || n_value > MAX_TYPES || capacity_value < 0 || capacity_value > MAX_CAPACITY) return -1;
    usz n = (usz)n_value, capacity = (usz)capacity_value;
    if (length != 2 + 3 * n) return -1;
    for (usz item = 0; item < n; ++item) {
        long weight = input[2 + 3 * item], value = input[3 + 3 * item], count = input[4 + 3 * item];
        if (weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16) return -1;
    }

    long[65] best;
    for (usz limit = 0; limit <= capacity; ++limit) best[limit] = 0;
    for (usz item = 0; item < n; ++item) {
        usz weight = (usz)input[2 + 3 * item];
        long value = input[3 + 3 * item];
        usz remaining = (usz)input[4 + 3 * item];
        usz bundle_size = 1;
        while (remaining > 0) {
            usz copies = bundle_size < remaining ? bundle_size : remaining;
            usz bundle_weight = weight * copies;
            long bundle_value = value * (long)copies;
            if (bundle_weight <= capacity) {
                usz limit = capacity;
                while (limit >= bundle_weight) {
                    long candidate = best[limit - bundle_weight] + bundle_value;
                    if (candidate > best[limit]) best[limit] = candidate;
                    if (limit == bundle_weight) break;
                    limit--;
                }
            }
            remaining -= copies;
            bundle_size *= 2;
        }
    }
    return best[capacity];
}
