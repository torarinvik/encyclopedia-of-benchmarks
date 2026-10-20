#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INPUT_LENGTH 7
#define MAX_OUTPUT_BYTES 152
#define COORDINATE_SCALE INT64_C(1000000)

static int64_t orient(int64_t ax, int64_t ay, int64_t bx, int64_t by,
                      int64_t cx, int64_t cy)
{
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

static int64_t round_ratio_away(int64_t numerator, int64_t denominator)
{
    const int64_t magnitude = numerator < 0 ? -numerator : numerator;
    const int64_t rounded = (magnitude + denominator / 2) / denominator;
    return numerator < 0 ? -rounded : rounded;
}

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)bits;
        bits >>= 8;
    }
}

int64_t delaunay_mesh_refinement(const int64_t *values, size_t length,
                                 uint8_t *output, size_t capacity)
{
    if (values == NULL || length != INPUT_LENGTH || values[0] != 3) return -1;
    int64_t x[3], y[3];
    for (int i = 0; i < 3; ++i) {
        x[i] = values[1 + 2 * i];
        y[i] = values[2 + 2 * i];
        if (x[i] < -100 || x[i] > 100 || y[i] < -100 || y[i] > 100) return -1;
        for (int j = 0; j < i; ++j)
            if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    const int64_t area2 = orient(x[0], y[0], x[1], y[1], x[2], y[2]);
    if (area2 <= 0) return -1;
    for (int i = 0; i < 3; ++i) {
        const int j = (i + 1) % 3, k = (i + 2) % 3;
        const int64_t ux = x[j] - x[i], uy = y[j] - y[i];
        const int64_t vx = x[k] - x[i], vy = y[k] - y[i];
        if (ux * vx + uy * vy <= 0) return -1;
    }

    const double len01 = sqrt((double)((x[1] - x[0]) * (x[1] - x[0]) + (y[1] - y[0]) * (y[1] - y[0])));
    const double len12 = sqrt((double)((x[2] - x[1]) * (x[2] - x[1]) + (y[2] - y[1]) * (y[2] - y[1])));
    const double len20 = sqrt((double)((x[0] - x[2]) * (x[0] - x[2]) + (y[0] - y[2]) * (y[0] - y[2])));
    const double shortest = fmin(len01, fmin(len12, len20));
    const double ratio = (len01 * len12 * len20) / (2.0 * (double)area2 * shortest);
    const double beta = 1.0 / (2.0 * sin(3.14159265358979323846 / 9.0));
    const int refine = ratio > beta * (1.0 + 1e-12);

    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    const int vertex_count = refine ? 4 : 3;
    put_i64(staged, 0, vertex_count);
    for (int i = 0; i < 3; ++i) {
        put_i64(staged, 8 + 16 * (size_t)i, x[i] * COORDINATE_SCALE);
        put_i64(staged, 16 + 16 * (size_t)i, y[i] * COORDINATE_SCALE);
    }
    if (refine) {
        const int64_t ax = x[0], ay = y[0];
        const int64_t bax = x[1] - ax, bay = y[1] - ay;
        const int64_t cax = x[2] - ax, cay = y[2] - ay;
        const int64_t denominator = 2 * (bax * cay - bay * cax);
        const int64_t balen_sq = bax * bax + bay * bay;
        const int64_t calen_sq = cax * cax + cay * cay;
        const int64_t center_x_num = ax * denominator + cay * balen_sq - bay * calen_sq;
        const int64_t center_y_num = ay * denominator + bax * calen_sq - cax * balen_sq;
        put_i64(staged, 56, round_ratio_away(center_x_num * COORDINATE_SCALE, denominator));
        put_i64(staged, 64, round_ratio_away(center_y_num * COORDINATE_SCALE, denominator));
        put_i64(staged, 72, 3);
        put_i64(staged, 80, 0); put_i64(staged, 88, 1); put_i64(staged, 96, 3);
        put_i64(staged, 104, 1); put_i64(staged, 112, 2); put_i64(staged, 120, 3);
        put_i64(staged, 128, 2); put_i64(staged, 136, 0); put_i64(staged, 144, 3);
    } else {
        put_i64(staged, 56, 1);
        put_i64(staged, 64, 0); put_i64(staged, 72, 1); put_i64(staged, 80, 2);
    }
    const size_t required = refine ? MAX_OUTPUT_BYTES : 88;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
