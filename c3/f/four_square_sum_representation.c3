module four_square_sum_representation;

fn long four_square_floor_sqrt(long value) {
    long root = 0;
    while ((root + 1) * (root + 1) <= value) root += 1;
    return root;
}

fn long four_square_pack(long a, long b, long c, long d) {
    return (((a * 33 + b) * 33 + c) * 33 + d);
}

fn long four_square_sum_representation(long* input, usz length)
    @export("four_square_sum_representation") {
    if (input == null || length != 1) return -1;
    long n = input[0];
    if (n < 0 || n > 1024) return -1;

    for (long a = four_square_floor_sqrt(n); a >= 0; a -= 1) {
        long rem_a = n - a * a;
        long b_max = four_square_floor_sqrt(rem_a);
        if (b_max > a) b_max = a;
        for (long b = b_max; b >= 0; b -= 1) {
            long rem_b = rem_a - b * b;
            long c_max = four_square_floor_sqrt(rem_b);
            if (c_max > b) c_max = b;
            for (long c = c_max; c >= 0; c -= 1) {
                long rem_c = rem_b - c * c;
                long d = four_square_floor_sqrt(rem_c);
                if (d <= c && d * d == rem_c) return four_square_pack(a, b, c, d);
            }
        }
    }
    return -2;
}
