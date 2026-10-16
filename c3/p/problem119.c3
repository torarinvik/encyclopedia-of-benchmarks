module problem119;

fn long digit_sum(long value) {
    long sum = 0;
    while (value > 0) { sum += value % 10; value /= 10; }
    return sum;
}

fn long problem119(long index) @export("problem119") {
    if (index < 1 || index > 30) return -1;
    long[10000] values;
    int count = 0;
    for (long base = 2; base < 100; base++) {
        long value = base * base;
        for (int exponent = 2; exponent < 100; exponent++) {
            if (digit_sum(value) == base) values[count++] = value;
            if (value > 9223372036854775807 / base) break;
            value *= base;
        }
    }
    for (int i = 1; i < count; i++) {
        long value = values[i];
        int j = i;
        while (j > 0 && values[j - 1] > value) { values[j] = values[j - 1]; j--; }
        values[j] = value;
    }
    return values[index - 1];
}
