module problem86;

const long MAX_LIMIT = 1000000;

fn bool is_square(long value) {
    long root = value;
    long next = (root + 1) / 2;
    while (next < root) { root = next; next = (root + value / root) / 2; }
    return root * root == value;
}

fn long problem86(long limit) @export("problem86") {
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    long cuboid_count = 0;
    long max_side = 0;
    while (cuboid_count <= limit) {
        max_side++;
        for (long sum_sides = 2; sum_sides <= 2 * max_side; sum_sides++) {
            if (!is_square(sum_sides * sum_sides + max_side * max_side)) continue;
            long high = max_side < sum_sides / 2 ? max_side : sum_sides / 2;
            long low = sum_sides - max_side > 1 ? sum_sides - max_side : 1;
            cuboid_count += high - low + 1;
        }
    }
    return max_side;
}
