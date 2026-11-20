module left_truncatable_prime_search;

const long MAX_LIMIT = 100000;
const usz MAX_QUEUE = 70000;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (long divisor = 3; divisor * divisor <= value; divisor += 2)
        if (value % divisor == 0) return false;
    return true;
}

fn long search(long base, long digits) {
    long[MAX_QUEUE] queue = {};
    usz end = 0;
    for (long value = 2; value < base; value += 1)
        if (is_prime(value)) queue[end++] = value;
    long best = queue[end - 1];
    usz level_start = 0, level_end = end;
    long place = base;
    for (long width = 1; width < digits && level_start < level_end; width += 1) {
        for (usz index = level_start; index < level_end; index += 1) {
            long suffix = queue[index];
            for (long leading = 1; leading < base; leading += 1) {
                long candidate = leading * place + suffix;
                if (is_prime(candidate)) {
                    if (end >= MAX_QUEUE) return -1;
                    queue[end++] = candidate;
                    if (candidate > best) best = candidate;
                }
            }
        }
        level_start = level_end;
        level_end = end;
        place *= base;
    }
    return best;
}

fn long left_truncatable_prime_search(long* input, usz length) @export("left_truncatable_prime_search") {
    if (input == null || length < 2 || length > 3) return -1;
    long base = input[0], digits = input[1];
    if (length != 2 || base < 3 || base > 16 || digits < 1 || digits > 10) return -1;
    long limit = 1;
    for (long index = 0; index < digits; index += 1) limit *= base;
    if (limit > MAX_LIMIT) return -1;
    return search(base, digits);
}
