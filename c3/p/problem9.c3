module problem9;

fn long problem9(long total) @export("problem9") {
    if (total < 3 || total > 1000) return -1;
    for (long a = 1; a <= total / 3; a++) {
        for (long b = a + 1; 2 * b < total - a; b++) {
            long c = total - a - b;
            if (a * a + b * b == c * c) return a * b * c;
        }
    }
    return -1;
}
