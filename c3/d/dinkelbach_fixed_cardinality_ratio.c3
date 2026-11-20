module dinkelbach_fixed_cardinality_ratio;

const usz MAX_ITEMS = 12;
const usz MAX_INPUT_LENGTH = 27;
const long RATIO_BASE = 120001;

fn long gcd_positive(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long choose_small(usz n, usz k) {
    if (k > n - k) k = n - k;
    long result = 1;
    for (usz index = 1; index <= k; index++)
        result = result * (n - k + index).long() / index.long();
    return result;
}

fn bool score_precedes(usz candidate, usz current, long* scores) {
    if (scores[candidate] != scores[current]) return scores[candidate] > scores[current];
    return candidate < current;
}

fn long dinkelbach_fixed_cardinality_ratio(long* input, usz length)
    @export("dinkelbach_fixed_cardinality_ratio") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    long k_value = input[1];
    if (n_value < 1 || n_value > MAX_ITEMS.long() || k_value < 1 || k_value > n_value ||
        length != 2 + 2 * n_value.usz()) return -1;

    usz n = n_value.usz();
    usz k = k_value.usz();
    long[MAX_ITEMS] numerators = zeroed;
    long[MAX_ITEMS] denominators = zeroed;
    for (usz item = 0; item < n; item++) {
        long numerator = input[2 + 2 * item];
        long denominator = input[3 + 2 * item];
        if (numerator < 0 || numerator > 10000 || denominator < 1 || denominator > 10000)
            return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
    }

    long ratio_numerator = 0;
    long ratio_denominator = 1;
    long iteration_limit = choose_small(n, k) + 1;
    for (long iteration = 0; iteration < iteration_limit; iteration++) {
        long[MAX_ITEMS] scores = zeroed;
        usz[MAX_ITEMS] order = zeroed;
        for (usz item = 0; item < n; item++) {
            scores[item] = numerators[item] * ratio_denominator -
                           ratio_numerator * denominators[item];
            order[item] = item;
        }
        for (usz item = 1; item < n; item++) {
            usz current = order[item];
            usz position = item;
            while (position > 0 && score_precedes(current, order[position - 1], &scores[0])) {
                order[position] = order[position - 1];
                position -= 1;
            }
            order[position] = current;
        }

        long selected_numerator = 0;
        long selected_denominator = 0;
        for (usz rank = 0; rank < k; rank++) {
            usz item = order[rank];
            selected_numerator += numerators[item];
            selected_denominator += denominators[item];
        }
        long residual = selected_numerator * ratio_denominator -
                        ratio_numerator * selected_denominator;
        if (residual < 0) return -1;
        if (residual == 0) {
            long divisor = gcd_positive(selected_numerator, selected_denominator);
            return (selected_numerator / divisor) * RATIO_BASE + selected_denominator / divisor;
        }

        long divisor = gcd_positive(selected_numerator, selected_denominator);
        ratio_numerator = selected_numerator / divisor;
        ratio_denominator = selected_denominator / divisor;
    }
    return -1;
}
