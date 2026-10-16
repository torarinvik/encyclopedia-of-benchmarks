module problem92;

const long MAX_LIMIT = 10000000;
const usz MAX_DIGITS = 7;
const usz MAX_SUM = MAX_DIGITS * 81 + 1;

fn u32 digit_square_sum(u32 value) {
    u32 total = 0;
    while (value != 0) {
        u32 digit = value % 10;
        total += digit * digit;
        value /= 10;
    }
    return total;
}

fn bool reaches_89(u32 value) {
    while (value != 1 && value != 89) value = digit_square_sum(value);
    return value == 89;
}

fn long problem92(long number) @export("problem92") {
    if (number < 0 || number > MAX_LIMIT) return -1;
    u32[MAX_DIGITS] digits;
    u32[MAX_DIGITS] reversed;
    usz digit_count = 0;
    if (number > 1) {
        u32 remaining = (number - 1).u32();
        while (remaining != 0) {
            reversed[digit_count++] = remaining % 10;
            remaining /= 10;
        }
        for (usz index = 0; index < digit_count; index++) digits[index] = reversed[digit_count - index - 1];
    } else {
        digits[digit_count++] = 0;
    }
    usz sum_limit = digit_count * 81 + 1;
    long[MAX_SUM] tight;
    long[MAX_SUM] free_counts;
    long[MAX_SUM] next_tight;
    long[MAX_SUM] next_free;
    for (usz sum = 0; sum < MAX_SUM; sum++) {
        tight[sum] = 0;
        free_counts[sum] = 0;
    }
    tight[0] = 1;
    for (usz position = 0; position < digit_count; position++) {
        for (usz sum = 0; sum < MAX_SUM; sum++) {
            next_tight[sum] = 0;
            next_free[sum] = 0;
        }
        u32 bound_digit = digits[position];
        for (usz sum = 0; sum < sum_limit; sum++) {
            if (tight[sum] != 0) {
                for (u32 digit = 0; digit <= bound_digit; digit++) {
                    usz next_sum = sum + (digit * digit).usz();
                    if (next_sum >= sum_limit) continue;
                    if (digit == bound_digit) next_tight[next_sum] += tight[sum];
                    else next_free[next_sum] += tight[sum];
                }
            }
            if (free_counts[sum] != 0) {
                for (u32 digit = 0; digit <= 9; digit++) {
                    usz next_sum = sum + (digit * digit).usz();
                    if (next_sum < sum_limit) next_free[next_sum] += free_counts[sum];
                }
            }
        }
        for (usz sum = 0; sum < MAX_SUM; sum++) {
            tight[sum] = next_tight[sum];
            free_counts[sum] = next_free[sum];
        }
    }
    long result = 0;
    for (usz sum = 1; sum < sum_limit; sum++)
        if (reaches_89(sum.u32())) result += tight[sum] + free_counts[sum];
    return result;
}
