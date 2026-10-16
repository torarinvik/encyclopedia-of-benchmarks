module problem25;

fn long problem25(long requested_digits) @export("problem25") {
    if (requested_digits < 2 || requested_digits > 1000) return -1;
    long[1000] previous;
    long[1000] current;
    long[1000] next;
    previous[0] = 1;
    current[0] = 1;
    long active_digits = 1;
    long index = 2;
    while (active_digits < requested_digits) {
        long carry = 0;
        for (usz position = 0; position < (usz)active_digits; position++) {
            long total = previous[position] + current[position] + carry;
            next[position] = total % 10;
            carry = total / 10;
        }
        if (carry != 0) {
            next[(usz)active_digits] = carry;
            active_digits++;
        }
        for (usz position = 0; position < (usz)active_digits; position++) {
            previous[position] = current[position];
            current[position] = next[position];
        }
        index++;
    }
    return index;
}
