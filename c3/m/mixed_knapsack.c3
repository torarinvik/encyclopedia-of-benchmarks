module mixed_knapsack;

const long MAX_TYPES = 16;
const long MAX_CAPACITY = 64;
const usz MAX_INPUT = 67;

fn long mixed_knapsack(long* input, usz length) @export("mixed_knapsack") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0], capacity_value = input[1];
    if (n_value < 0 || n_value > MAX_TYPES || capacity_value < 0 || capacity_value > MAX_CAPACITY) return -1;
    usz n = (usz)n_value, capacity = (usz)capacity_value;
    if (length != 2 + 4 * n) return -1;
    for (usz item = 0; item < n; ++item) {
        long mode = input[2 + 4 * item], weight = input[3 + 4 * item];
        long value = input[4 + 4 * item], limit = input[5 + 4 * item];
        if (mode < 0 || mode > 2 || weight < 1 || weight > 16 || value < 0 || value > 100) return -1;
        if ((mode == 0 && limit != 1) || (mode == 1 && limit != 0) || (mode == 2 && (limit < 0 || limit > 16))) return -1;
    }

    long[65] best;
    for (usz cap = 0; cap <= capacity; ++cap) best[cap] = 0;
    for (usz item = 0; item < n; ++item) {
        long mode = input[2 + 4 * item], value = input[4 + 4 * item];
        usz weight = (usz)input[3 + 4 * item];
        if (mode == 0) {
            usz cap = capacity;
            while (cap >= weight) {
                long candidate = best[cap - weight] + value;
                if (candidate > best[cap]) best[cap] = candidate;
                if (cap == weight) break;
                cap--;
            }
        } else if (mode == 1) {
            for (usz cap = weight; cap <= capacity; ++cap) {
                long candidate = best[cap - weight] + value;
                if (candidate > best[cap]) best[cap] = candidate;
            }
        } else {
            usz remaining = (usz)input[5 + 4 * item], bundle_size = 1;
            while (remaining > 0) {
                usz copies = bundle_size < remaining ? bundle_size : remaining;
                usz bundle_weight = copies * weight;
                long bundle_value = (long)copies * value;
                if (bundle_weight <= capacity) {
                    usz cap = capacity;
                    while (cap >= bundle_weight) {
                        long candidate = best[cap - bundle_weight] + bundle_value;
                        if (candidate > best[cap]) best[cap] = candidate;
                        if (cap == bundle_weight) break;
                        cap--;
                    }
                }
                remaining -= copies;
                bundle_size *= 2;
            }
        }
    }
    return best[capacity];
}
