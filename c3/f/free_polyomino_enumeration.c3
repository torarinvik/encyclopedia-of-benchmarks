module free_polyomino_enumeration;

const int FP_MAX_N = 8;
const int FP_MAX_SHAPES = 512;
const int FP_LAYER_WORDS = FP_MAX_SHAPES * FP_MAX_N;

fn void fp_canonical(long* xs, long* ys, int size, long* result) {
    long[FP_MAX_N] best = zeroed;
    bool have_best = false;
    for (int mode = 0; mode < 8; mode++) {
        long[FP_MAX_N] tx = zeroed, ty = zeroed, codes = zeroed;
        long min_x = 1000, min_y = 1000;
        for (int i = 0; i < size; i++) {
            long a = mode >= 4 ? ys[i] : xs[i];
            long b = mode >= 4 ? xs[i] : ys[i];
            if (mode & 1) a = -a;
            if (mode & 2) b = -b;
            tx[i] = a; ty[i] = b;
            if (a < min_x) min_x = a;
            if (b < min_y) min_y = b;
        }
        for (int i = 0; i < size; i++) {
            codes[i] = (tx[i] - min_x) * 8 + ty[i] - min_y;
            int j = i;
            while (j > 0 && codes[j] < codes[j - 1]) {
                long temporary = codes[j]; codes[j] = codes[j - 1]; codes[j - 1] = temporary;
                j--;
            }
        }
        bool less = !have_best;
        if (have_best) {
            for (int i = 0; i < size; i++) {
                if (codes[i] != best[i]) { less = codes[i] < best[i]; break; }
            }
        }
        if (less) {
            for (int i = 0; i < size; i++) best[i] = codes[i];
            have_best = true;
        }
    }
    for (int i = 0; i < size; i++) result[i] = best[i];
}

fn long free_polyomino_enumeration(long* input, usz length) @export("free_polyomino_enumeration") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > FP_MAX_N) return -1;
    int n = (int)input[0];
    long[2 * FP_LAYER_WORDS] shapes = zeroed;
    shapes[0] = 0;
    int current = 0, shape_count = 1;
    int[4] dx = {1, -1, 0, 0}, dy = {0, 0, 1, -1};
    for (int size = 1; size < n; size++) {
        int next = 1 - current, next_count = 0;
        for (int s = 0; s < shape_count; s++) {
            for (int cell = 0; cell < size; cell++) {
                long code = shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + cell];
                int x = (int)(code / 8), y = (int)(code % 8);
                for (int direction = 0; direction < 4; direction++) {
                    int nx = x + dx[direction], ny = y + dy[direction];
                    bool occupied = false;
                    if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                        long neighbor = nx * 8 + ny;
                        for (int i = 0; i < size; i++)
                            if (shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i] == neighbor) occupied = true;
                    }
                    if (occupied) continue;
                    long[FP_MAX_N] xs = zeroed, ys = zeroed, candidate = zeroed;
                    for (int i = 0; i < size; i++) {
                        long previous = shapes[current * FP_LAYER_WORDS + s * FP_MAX_N + i];
                        xs[i] = previous / 8; ys[i] = previous % 8;
                    }
                    xs[size] = nx; ys[size] = ny;
                    fp_canonical(&xs[0], &ys[0], size + 1, &candidate[0]);
                    bool duplicate = false;
                    for (int old = 0; old < next_count && !duplicate; old++) {
                        bool same = true;
                        for (int i = 0; i <= size; i++)
                            if (shapes[next * FP_LAYER_WORDS + old * FP_MAX_N + i] != candidate[i]) same = false;
                        if (same) duplicate = true;
                    }
                    if (!duplicate) {
                        if (next_count == FP_MAX_SHAPES) return -1;
                        for (int i = 0; i <= size; i++) shapes[next * FP_LAYER_WORDS + next_count * FP_MAX_N + i] = candidate[i];
                        next_count++;
                    }
                }
            }
        }
        current = next; shape_count = next_count;
    }
    return shape_count;
}
