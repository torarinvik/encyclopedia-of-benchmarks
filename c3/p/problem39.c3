module problem39;

const long MAX_SQRT = 1415;

fn long integer_sqrt(long value) {
    long low = 0, high = MAX_SQRT;
    while (high - low > 1) {
        long middle = (low + high) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

fn long problem39(long limit) @export("problem39") {
    if (limit < 12 || limit > 1000) return -1;
    long[1001] counts = {0};
    long[1001] first_order = {0};
    long next_order = 1;
    for (long base = 1; base <= limit; base++) {
        for (long perpendicular = base; perpendicular <= limit; perpendicular++) {
            long square_sum = base * base + perpendicular * perpendicular;
            long hypotenuse = integer_sqrt(square_sum);
            if (hypotenuse * hypotenuse != square_sum) continue;
            long perimeter = base + perpendicular + hypotenuse;
            if (perimeter > limit) continue;
            if (counts[(usz)perimeter] == 0) {
                first_order[(usz)perimeter] = next_order;
                next_order++;
            }
            counts[(usz)perimeter]++;
        }
    }
    long best_perimeter = -1, best_count = 0, best_order = 9223372036854775807L;
    for (long perimeter = 1; perimeter <= limit; perimeter++) {
        if (counts[(usz)perimeter] > 0 &&
            (counts[(usz)perimeter] > best_count ||
             (counts[(usz)perimeter] == best_count && first_order[(usz)perimeter] < best_order))) {
            best_perimeter = perimeter;
            best_count = counts[(usz)perimeter];
            best_order = first_order[(usz)perimeter];
        }
    }
    return best_perimeter;
}
