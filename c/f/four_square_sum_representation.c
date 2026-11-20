#include <stddef.h>
#include <stdint.h>

static int64_t four_square_floor_sqrt(int64_t value) {
    int64_t root = 0;
    while ((root + 1) * (root + 1) <= value) ++root;
    return root;
}

static int64_t four_square_pack(int64_t a, int64_t b, int64_t c, int64_t d) {
    return (((a * 33 + b) * 33 + c) * 33 + d);
}

int64_t four_square_sum_representation(const int64_t *input, size_t length) {
    if (input == 0 || length != 1) return -1;
    const int64_t n = input[0];
    if (n < 0 || n > 1024) return -1;

    for (int64_t a = four_square_floor_sqrt(n); a >= 0; --a) {
        const int64_t rem_a = n - a * a;
        int64_t b_max = four_square_floor_sqrt(rem_a);
        if (b_max > a) b_max = a;
        for (int64_t b = b_max; b >= 0; --b) {
            const int64_t rem_b = rem_a - b * b;
            int64_t c_max = four_square_floor_sqrt(rem_b);
            if (c_max > b) c_max = b;
            for (int64_t c = c_max; c >= 0; --c) {
                const int64_t rem_c = rem_b - c * c;
                const int64_t d = four_square_floor_sqrt(rem_c);
                if (d <= c && d * d == rem_c) return four_square_pack(a, b, c, d);
            }
        }
    }
    return -2;
}
