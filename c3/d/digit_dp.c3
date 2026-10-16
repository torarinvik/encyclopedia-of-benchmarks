const MAX_DIGITS: usz = 19;
const MAX_DIGIT_SUM: usz = 171;
const MAX_INPUT_LENGTH: usz = 4;
const MIN_BOUND: long = -1;
const MAX_BOUND: long = 1000000000000000000;

fn long count_up_to(long bound, usz target) {
    if (bound < 0) return 0;
    usz[MAX_DIGITS] digits = zeroed;
    usz digit_count = 0;
    do {
        digits[digit_count++] = (usz)(bound % 10);
        bound /= 10;
    } while (bound > 0);

    long[MAX_DIGIT_SUM + 1] loose = zeroed;
    long[MAX_DIGIT_SUM + 1] tight = zeroed;
    tight[0] = 1;
    while (digit_count > 0) {
        usz limit = digits[--digit_count];
        long[MAX_DIGIT_SUM + 1] next_loose = zeroed;
        long[MAX_DIGIT_SUM + 1] next_tight = zeroed;
        for (usz sum = 0; sum <= target; sum++) {
            for (usz digit = 0; digit <= 9 && sum + digit <= target; digit++)
                next_loose[sum + digit] += loose[sum];
            for (usz digit = 0; digit <= limit && sum + digit <= target; digit++) {
                if (digit == limit) next_tight[sum + digit] += tight[sum];
                else next_loose[sum + digit] += tight[sum];
            }
        }
        for (usz sum = 0; sum <= target; sum++) {
            loose[sum] = next_loose[sum];
            tight[sum] = next_tight[sum];
        }
    }
    return loose[target] + tight[target];
}

fn long digit_dp(long* input, usz length) @export("digit_dp") {
    if (input == null || length > MAX_INPUT_LENGTH || length != 3) return -1;
    long lower = input[0], upper = input[1], target_value = input[2];
    if (lower < MIN_BOUND || lower > MAX_BOUND || upper < MIN_BOUND || upper > MAX_BOUND
        || target_value < -2147483648 || target_value > 2147483647) return -1;
    if (lower > upper || target_value < 0 || target_value > (long)MAX_DIGIT_SUM) return 0;
    usz target = (usz)target_value;
    return count_up_to(upper, target) - count_up_to(lower - 1, target);
}
