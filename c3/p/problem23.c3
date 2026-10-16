module problem23;

const long MAX_LIMIT = 28123;

fn long problem23(long limit) @export("problem23") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    usz bound = (usz)limit;
    long[MAX_LIMIT + 1] proper_divisor_sums;
    bool[MAX_LIMIT + 1] abundant;
    bool[MAX_LIMIT + 1] representable;
    for (usz index = 0; index <= bound; index++) {
        proper_divisor_sums[index] = 0;
        abundant[index] = false;
        representable[index] = false;
    }

    for (usz divisor = 1; divisor <= bound / 2; divisor++) {
        for (usz multiple = 2 * divisor; multiple <= bound; multiple += divisor) {
            proper_divisor_sums[multiple] += (long)divisor;
        }
    }
    for (usz value = 12; value <= bound; value++) {
        abundant[value] = proper_divisor_sums[value] > (long)value;
    }
    for (usz left = 12; left <= bound; left++) {
        if (!abundant[left]) continue;
        for (usz right = left; right <= bound - left; right++) {
            if (abundant[right]) representable[left + right] = true;
        }
    }

    long total = 0;
    for (usz value = 1; value <= bound; value++) {
        if (!representable[value]) total += (long)value;
    }
    return total;
}
