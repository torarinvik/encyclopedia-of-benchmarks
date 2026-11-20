module fractional_programming_ratio_knapsack_binary_search;

const usz MAX_ITEMS = 12;
const usz MAX_WEIGHT = 32;
const usz MAX_PARSEABLE_INPUT = 27;
const long SCALE = 1000000;
const long MAX_SCALED_RATIO = 1000000000;
const long NEGATIVE_INFINITY = -2305843009213693952;

fn bool ratio_feasible(long* numerators, long* denominators, usz n,
                       usz required_weight, long threshold) {
    long[33] current = zeroed;
    long[33] next = zeroed;
    for (usz weight = 0; weight <= required_weight; weight++)
        current[weight] = NEGATIVE_INFINITY;
    current[0] = 0;
    for (usz item = 0; item < n; item++) {
        for (usz weight = 0; weight <= required_weight; weight++)
            next[weight] = current[weight];
        long score = SCALE * numerators[item] - threshold * denominators[item];
        for (usz weight = 0; weight <= required_weight; weight++) {
            if (current[weight] == NEGATIVE_INFINITY) continue;
            usz sum = weight + denominators[item].usz();
            usz target = if sum < required_weight: sum else: required_weight;
            long candidate = current[weight] + score;
            if (candidate > next[target]) next[target] = candidate;
        }
        for (usz weight = 0; weight <= required_weight; weight++)
            current[weight] = next[weight];
    }
    return current[required_weight] >= 0;
}

fn long fractional_programming_ratio_knapsack_binary_search(long* input, usz length)
    @export("fractional_programming_ratio_knapsack_binary_search") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    long n_value = input[0];
    long required_value = input[1];
    if (n_value < 1 || n_value > MAX_ITEMS.long() || required_value < 1 ||
        required_value > MAX_WEIGHT.long() || length != 2 + 2 * n_value.usz()) return -1;

    usz n = n_value.usz();
    usz required_weight = required_value.usz();
    long[MAX_ITEMS] numerators = zeroed;
    long[MAX_ITEMS] denominators = zeroed;
    long denominator_sum = 0;
    for (usz item = 0; item < n; item++) {
        long numerator = input[2 + 2 * item];
        long denominator = input[3 + 2 * item];
        if (numerator < 0 || numerator > 1000 || denominator < 1 || denominator > 8)
            return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
        denominator_sum += denominator;
    }
    if (required_value > denominator_sum) return -1;

    long low = 0;
    long high = MAX_SCALED_RATIO + 1;
    while (high - low > 1) {
        long middle = low + (high - low) / 2;
        if (ratio_feasible(&numerators[0], &denominators[0], n, required_weight, middle))
            low = middle;
        else
            high = middle;
    }
    return low;
}
