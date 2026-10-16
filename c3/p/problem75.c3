module problem75;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long MAX_LIMIT = 1500000;

fn long gcd_i64(long left, long right) {
    while (right != 0) { long remainder = left % right; left = right; right = remainder; }
    return left;
}

fn long problem75(long limit) @export("problem75") {
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    u8* frequency = (u8*)calloc((usz)limit + 1, sizeof(u8));
    if (frequency == null) return -1;
    defer free(frequency);
    for (long m = 2; 2 * m * (m + 1) <= limit; m++) {
        for (long n = (m % 2) + 1; n < m; n += 2) {
            if (gcd_i64(m, n) != 1) continue;
            long primitive_perimeter = 2 * m * (m + n);
            for (long perimeter = primitive_perimeter; perimeter <= limit; perimeter += primitive_perimeter) {
                if (frequency[(usz)perimeter] < 2) frequency[(usz)perimeter]++;
            }
        }
    }
    long unique = 0;
    for (usz perimeter = 1; perimeter <= (usz)limit; perimeter++) if (frequency[perimeter] == 1) unique++;
    return unique;
}
