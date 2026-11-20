#include <stddef.h>
#include <stdint.h>

#define FP_MAX_N 8
#define FP_MAX_SHAPES 512

static void fp_canonical(const int xs[FP_MAX_N], const int ys[FP_MAX_N], int size,
                         int result[FP_MAX_N]) {
    int best[FP_MAX_N];
    int have_best = 0;
    for (int mode = 0; mode < 8; ++mode) {
        int tx[FP_MAX_N], ty[FP_MAX_N], codes[FP_MAX_N];
        int min_x = 1000, min_y = 1000;
        for (int i = 0; i < size; ++i) {
            int a = mode >= 4 ? ys[i] : xs[i];
            int b = mode >= 4 ? xs[i] : ys[i];
            if (mode & 1) a = -a;
            if (mode & 2) b = -b;
            tx[i] = a;
            ty[i] = b;
            if (a < min_x) min_x = a;
            if (b < min_y) min_y = b;
        }
        for (int i = 0; i < size; ++i) {
            codes[i] = (tx[i] - min_x) * 8 + (ty[i] - min_y);
            int j = i;
            while (j > 0 && codes[j] < codes[j - 1]) {
                int swap = codes[j]; codes[j] = codes[j - 1]; codes[j - 1] = swap;
                --j;
            }
        }
        int less = !have_best;
        if (have_best) {
            for (int i = 0; i < size; ++i) {
                if (codes[i] != best[i]) { less = codes[i] < best[i]; break; }
            }
        }
        if (less) {
            for (int i = 0; i < size; ++i) best[i] = codes[i];
            have_best = 1;
        }
    }
    for (int i = 0; i < size; ++i) result[i] = best[i];
}

int64_t free_polyomino_enumeration(const int64_t *input, size_t length) {
    if (input == NULL || length != 1 || input[0] < 1 || input[0] > FP_MAX_N) return -1;
    int n = (int)input[0];
    int shapes[2][FP_MAX_SHAPES][FP_MAX_N] = {{{0}}};
    shapes[0][0][0] = 0;
    int current = 0, shape_count = 1;
    const int dx[4] = {1, -1, 0, 0};
    const int dy[4] = {0, 0, 1, -1};

    for (int size = 1; size < n; ++size) {
        int next = 1 - current;
        int next_count = 0;
        for (int s = 0; s < shape_count; ++s) {
            for (int cell = 0; cell < size; ++cell) {
                int code = shapes[current][s][cell];
                int x = code / 8, y = code % 8;
                for (int direction = 0; direction < 4; ++direction) {
                    int nx = x + dx[direction], ny = y + dy[direction];
                    int occupied = 0;
                    if (0 <= nx && nx < 8 && 0 <= ny && ny < 8) {
                        int neighbor_code = nx * 8 + ny;
                        for (int i = 0; i < size; ++i)
                            if (shapes[current][s][i] == neighbor_code) occupied = 1;
                    }
                    if (occupied) continue;

                    int xs[FP_MAX_N], ys[FP_MAX_N], canonical[FP_MAX_N];
                    for (int i = 0; i < size; ++i) {
                        xs[i] = shapes[current][s][i] / 8;
                        ys[i] = shapes[current][s][i] % 8;
                    }
                    xs[size] = nx; ys[size] = ny;
                    fp_canonical(xs, ys, size + 1, canonical);
                    int duplicate = 0;
                    for (int existing = 0; existing < next_count && !duplicate; ++existing) {
                        int same = 1;
                        for (int i = 0; i <= size; ++i)
                            if (shapes[next][existing][i] != canonical[i]) same = 0;
                        if (same) duplicate = 1;
                    }
                    if (!duplicate) {
                        if (next_count == FP_MAX_SHAPES) return -1;
                        for (int i = 0; i <= size; ++i) shapes[next][next_count][i] = canonical[i];
                        ++next_count;
                    }
                }
            }
        }
        current = next;
        shape_count = next_count;
    }
    return shape_count;
}
