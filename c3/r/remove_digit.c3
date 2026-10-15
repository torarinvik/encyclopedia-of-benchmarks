module remove_digit;

const long INVALID_RESULT = -1;
const long MIN_VALID_INPUT = -9223372036854775807;

fn long remove_digit(long value) @export("remove_digit") {
    if (value < MIN_VALID_INPUT) return INVALID_RESULT;
    long magnitude = value < 0 ? -value : value;
    if (magnitude < 10) return INVALID_RESULT;

    long top_place = 1;
    while (top_place <= magnitude / 10) top_place *= 10;
    long digit_count = 0;
    for (long place = top_place; place > 0; place /= 10) digit_count++;
    long maximum = 0;
    for (long removed = 0; removed < digit_count; removed++) {
        long candidate = 0;
        long position = 0;
        for (long place = top_place; place > 0; place /= 10) {
            long digit = (magnitude / place) % 10;
            if (position != removed) candidate = candidate * 10 + digit;
            position++;
        }
        if (candidate > maximum) maximum = candidate;
    }
    return maximum;
}
