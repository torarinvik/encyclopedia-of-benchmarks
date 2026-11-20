module next_palindromic_number;

const long MAX_INPUT = 9999999999999999L;

fn long next_palindromic_number(long* values, usz length)
    @export("next_palindromic_number") {
    if (values == null || length != 1) return -1;
    long number = values[0];
    if (number < 0 || number > MAX_INPUT) return -1;

    uchar[17] digits;
    usz count = 0;
    long remaining = number;
    do {
        digits[count++] = (uchar)(remaining % 10);
        remaining /= 10;
    } while (remaining > 0);
    for (usz left = 0; left < count / 2; left++) {
        usz right = count - 1 - left;
        uchar swap = digits[left];
        digits[left] = digits[right];
        digits[right] = swap;
    }
    for (usz left = 0; left < count / 2; left++) digits[count - 1 - left] = digits[left];
    long candidate = 0;
    for (usz i = 0; i < count; i++) candidate = candidate * 10 + digits[i];
    if (candidate > number) return candidate;

    usz position = (count + 1) / 2;
    while (position > 0 && digits[position - 1] == 9) {
        digits[position - 1] = 0;
        position--;
    }
    if (position == 0) {
        long power = 1;
        for (usz i = 0; i < count; i++) power *= 10;
        return power + 1;
    }
    digits[position - 1]++;
    for (usz left = 0; left < count / 2; left++) digits[count - 1 - left] = digits[left];
    candidate = 0;
    for (usz i = 0; i < count; i++) candidate = candidate * 10 + digits[i];
    return candidate;
}
