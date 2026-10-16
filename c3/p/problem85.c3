// Search triangular-number products for the rectangle count nearest the target.
module problem85;

extern fn double sqrt(double value);
extern fn double floor(double value);
extern fn double ceil(double value);

const long MAX_TARGET = 2000000000;

fn long triangle(long side) {
    return side * (side + 1) / 2;
}

fn long absolute_difference(long left, long right) {
    long difference = left - right;
    return difference < 0 ? -difference : difference;
}

fn long problem85(long target) @export("problem85") {
    if (target < 0 || target > MAX_TARGET) return -1;
    long bound = (long)ceil(sqrt((double)(target * 2)) * 1.1);
    long best_product = 0;
    long area = 0;
    long triangle_a = 0;
    for (long a = 1; a < bound; a++) {
        triangle_a += a;
        double estimate = (-1.0 + sqrt(1.0 + 8.0 * (double)target / (double)triangle_a)) / 2.0;
        long b_floor = (long)floor(estimate);
        long b_ceil = (long)ceil(estimate);
        long first_product = triangle_a * triangle(b_floor);
        long second_product = triangle_a * triangle(b_ceil);
        if (absolute_difference(target, first_product) < absolute_difference(target, best_product)) {
            best_product = first_product;
            area = a * b_floor;
        }
        if (absolute_difference(target, second_product) < absolute_difference(target, best_product)) {
            best_product = second_product;
            area = a * b_ceil;
        }
    }
    return area;
}
