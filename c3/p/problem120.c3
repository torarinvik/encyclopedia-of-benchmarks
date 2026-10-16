module problem120;

const long MAX_LIMIT = 1000;

fn long problem120(long limit) @export("problem120") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    long total = 0;
    for (long a = 3; a <= limit; a++) total += 2 * a * ((a - 1) / 2);
    return total;
}
