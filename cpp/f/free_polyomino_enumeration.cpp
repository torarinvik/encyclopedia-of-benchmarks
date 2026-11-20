#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxN = 8;
constexpr int kMaxShapes = 512;

void canonical(const int xs[kMaxN], const int ys[kMaxN], int size, int result[kMaxN]) {
    int best[kMaxN]{};
    bool have_best = false;
    for (int mode = 0; mode < 8; ++mode) {
        int tx[kMaxN], ty[kMaxN], codes[kMaxN];
        int min_x = 1000, min_y = 1000;
        for (int i = 0; i < size; ++i) {
            int a = mode >= 4 ? ys[i] : xs[i];
            int b = mode >= 4 ? xs[i] : ys[i];
            if (mode & 1) a = -a;
            if (mode & 2) b = -b;
            tx[i] = a; ty[i] = b;
            if (a < min_x) min_x = a;
            if (b < min_y) min_y = b;
        }
        for (int i = 0; i < size; ++i) {
            codes[i] = (tx[i] - min_x) * 8 + (ty[i] - min_y);
            for (int j = i; j > 0 && codes[j] < codes[j - 1]; --j) {
                const int temp = codes[j]; codes[j] = codes[j - 1]; codes[j - 1] = temp;
            }
        }
        bool less = !have_best;
        if (have_best) {
            for (int i = 0; i < size; ++i) {
                if (codes[i] != best[i]) { less = codes[i] < best[i]; break; }
            }
        }
        if (less) {
            for (int i = 0; i < size; ++i) best[i] = codes[i];
            have_best = true;
        }
    }
    for (int i = 0; i < size; ++i) result[i] = best[i];
}
}

extern "C" std::int64_t free_polyomino_enumeration(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > kMaxN) return -1;
    const int n = static_cast<int>(input[0]);
    int shapes[2][kMaxShapes][kMaxN]{};
    shapes[0][0][0] = 0;
    int current = 0, shape_count = 1;
    constexpr int dx[4] = {1, -1, 0, 0};
    constexpr int dy[4] = {0, 0, 1, -1};
    for (int size = 1; size < n; ++size) {
        const int next = 1 - current;
        int next_count = 0;
        for (int s = 0; s < shape_count; ++s) {
            for (int cell = 0; cell < size; ++cell) {
                const int code = shapes[current][s][cell];
                const int x = code / 8, y = code % 8;
                for (int direction = 0; direction < 4; ++direction) {
                    const int nx = x + dx[direction], ny = y + dy[direction];
                    bool occupied = false;
                    if (0 <= nx && nx < 8 && 0 <= ny && ny < 8) {
                        const int neighbor_code = nx * 8 + ny;
                        for (int i = 0; i < size; ++i)
                            if (shapes[current][s][i] == neighbor_code) occupied = true;
                    }
                    if (occupied) continue;
                    int xs[kMaxN], ys[kMaxN], candidate[kMaxN];
                    for (int i = 0; i < size; ++i) {
                        xs[i] = shapes[current][s][i] / 8;
                        ys[i] = shapes[current][s][i] % 8;
                    }
                    xs[size] = nx; ys[size] = ny;
                    canonical(xs, ys, size + 1, candidate);
                    bool duplicate = false;
                    for (int old = 0; old < next_count && !duplicate; ++old) {
                        bool same = true;
                        for (int i = 0; i <= size; ++i)
                            if (shapes[next][old][i] != candidate[i]) same = false;
                        if (same) duplicate = true;
                    }
                    if (!duplicate) {
                        if (next_count == kMaxShapes) return -1;
                        for (int i = 0; i <= size; ++i) shapes[next][next_count][i] = candidate[i];
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
