module problem65;

const usz MAX_DIGITS = 256;

fn long problem65(long max_n) @export("problem65") {
    if (max_n < 1 || max_n > 100) return -1;
    long[MAX_DIGITS] previous;
    long[MAX_DIGITS] current;
    long[MAX_DIGITS] next;
    previous[0] = 1;
    current[0] = 2;
    long previous_length = 1;
    long current_length = 1;
    for (long i = 2; i <= max_n; i++) {
        long coefficient = i % 3 == 0 ? (2 * i) / 3 : 1;
        long carry = 0;
        for (usz position = 0; position < (usz)current_length; position++) {
            long old = (long)position < previous_length ? previous[position] : 0;
            long total = coefficient * current[position] + old + carry;
            next[position] = total % 10;
            carry = total / 10;
        }
        long next_length = current_length;
        while (carry != 0) {
            next[(usz)next_length++] = carry % 10;
            carry /= 10;
        }
        for (usz position = 0; position < (usz)current_length; position++) previous[position] = current[position];
        for (usz position = 0; position < (usz)next_length; position++) current[position] = next[position];
        previous_length = current_length;
        current_length = next_length;
    }
    long digit_sum = 0;
    for (usz position = 0; position < (usz)current_length; position++) digit_sum += current[position];
    return digit_sum;
}
