module pisinger_bounded_weight_subset_sum;

const int MAX_ITEMS = 32;
const long MAX_TARGET = 256;
const long MAX_WEIGHT = 12;
const usz MAX_PARSEABLE_INPUT_LENGTH = 35;

fn long pisinger_bounded_weight_subset_sum(long* input, usz length) @export("pisinger_bounded_weight_subset_sum") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long target_value = input[1];
    if (n_value < 0 || n_value > MAX_ITEMS || target_value < 0 || target_value > MAX_TARGET) return -1;
    int n = (int)n_value;
    if (length != (usz)(n + 2)) return -1;

    int width = 0;
    for (int index = 0; index < n; index++) {
        long weight = input[index + 2];
        if (weight < 1 || weight > MAX_WEIGHT) return -1;
        if (weight > width) width = (int)weight;
    }
    if (n == 0) return 0;

    int target = (int)target_value;
    int prefix_sum = 0;
    int break_index = 0;
    while (break_index < n && prefix_sum + (int)input[break_index + 2] <= target) {
        prefix_sum += (int)input[break_index + 2];
        break_index++;
    }
    if (break_index == n) return prefix_sum;

    int[24] previous = {};
    int[24] current = {};
    for (int slot = 0; slot < 2 * width; slot++) previous[slot] = -1;
    previous[prefix_sum + width - target - 1] = break_index;

    for (int item = break_index; item < n; item++) {
        for (int slot = 0; slot < 2 * width; slot++) current[slot] = previous[slot];
        int weight = (int)input[item + 2];
        for (int slot = 0; slot < width; slot++) {
            int destination = slot + weight;
            if (previous[slot] > current[destination]) current[destination] = previous[slot];
        }
        for (int slot = 2 * width - 1; slot >= width; slot--) {
            int first_item = previous[slot];
            if (first_item < 0) first_item = 0;
            int stop_item = current[slot];
            for (int removed = first_item; removed < stop_item; removed++) {
                int reduced = slot - (int)input[removed + 2];
                if (removed > current[reduced]) current[reduced] = removed;
            }
        }
        for (int slot = 0; slot < 2 * width; slot++) previous[slot] = current[slot];
    }

    int low_mass = 0;
    if (target >= width) low_mass = target - width + 1;
    for (int mass = target; mass >= low_mass; mass--) {
        if (previous[mass + width - target - 1] >= 0) return mass;
    }
    return 0;
}
