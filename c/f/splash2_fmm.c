#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { MAX_PARTICLES = 48, BOXES = 16, ORDER = 32, INV_ORDER = 2 * ORDER };

int64_t splash2_fmm(const double *input, size_t input_length,
                    double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 7 || input_length > 1 + 3 * MAX_PARTICLES) return -1;
    double requested_count = input[0];
    if (!(requested_count >= 2.0 && requested_count <= MAX_PARTICLES) ||
        requested_count != (double)(int)requested_count) return -1;
    size_t count = (size_t)requested_count;
    if (input_length != 1 + 3 * count) return -1;

    double x[MAX_PARTICLES], y[MAX_PARTICLES], charge[MAX_PARTICLES];
    int box[MAX_PARTICLES];
    for (size_t i = 0; i < count; ++i) {
        double px = input[1 + 3 * i], py = input[2 + 3 * i], q = input[3 + 3 * i];
        if (!(px >= 0.0 && px < 8.0) || px != (double)(int)px ||
            !(py >= 0.0 && py < 8.0) || py != (double)(int)py ||
            !(q >= -3.0 && q <= 3.0) || q != (double)(int)q) return -1;
        x[i] = px; y[i] = py; charge[i] = q;
        box[i] = ((int)py / 2) * 4 + (int)px / 2;
        for (size_t j = 0; j < i; ++j)
            if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    if (output == NULL || output_capacity < count) return -2;

    double multipole_re[BOXES][ORDER + 1] = {{0.0}};
    double multipole_im[BOXES][ORDER + 1] = {{0.0}};
    double local_re[BOXES][ORDER + 1] = {{0.0}};
    double local_im[BOXES][ORDER + 1] = {{0.0}};
    for (size_t i = 0; i < count; ++i) {
        int b = box[i], bx = b % 4, by = b / 4;
        double zr = x[i] - (2.0 * bx + 1.0), zi = y[i] - (2.0 * by + 1.0);
        double pr = 1.0, pi = 0.0;
        multipole_re[b][0] += charge[i];
        for (int k = 1; k <= ORDER; ++k) {
            double next_re = pr * zr - pi * zi;
            double next_im = pr * zi + pi * zr;
            pr = next_re; pi = next_im;
            multipole_re[b][k] += charge[i] * pr;
            multipole_im[b][k] += charge[i] * pi;
        }
    }

    for (int target = 0; target < BOXES; ++target) {
        int tx = target % 4, ty = target / 4;
        for (int source = 0; source < BOXES; ++source) {
            int sx = source % 4, sy = source / 4;
            int dx_box = tx - sx, dy_box = ty - sy;
            if (abs(dx_box) <= 1 && abs(dy_box) <= 1) continue;
            double dx = 2.0 * dx_box, dy = 2.0 * dy_box;
            double r2 = dx * dx + dy * dy;
            double inv_re[INV_ORDER + 1], inv_im[INV_ORDER + 1];
            inv_re[0] = 1.0; inv_im[0] = 0.0;
            double one_re = dx / r2, one_im = -dy / r2;
            for (int power = 1; power <= INV_ORDER; ++power) {
                inv_re[power] = inv_re[power - 1] * one_re - inv_im[power - 1] * one_im;
                inv_im[power] = inv_re[power - 1] * one_im + inv_im[power - 1] * one_re;
            }
            double constant = multipole_re[source][0] * 0.5 * log(r2);
            for (int k = 1; k <= ORDER; ++k)
                constant -= (multipole_re[source][k] * inv_re[k] -
                             multipole_im[source][k] * inv_im[k]) / (double)k;
            local_re[target][0] += constant;
            for (int n = 1; n <= ORDER; ++n) {
                double sum_re = 0.0, sum_im = 0.0;
                for (int k = 1; k <= ORDER; ++k) {
                    double choose = 1.0;
                    for (int j = 1; j <= n; ++j)
                        choose *= (double)(k + j - 1) / (double)j;
                    double scale = choose / (double)k;
                    int power = k + n;
                    sum_re += scale * (multipole_re[source][k] * inv_re[power] -
                                       multipole_im[source][k] * inv_im[power]);
                    sum_im += scale * (multipole_re[source][k] * inv_im[power] +
                                       multipole_im[source][k] * inv_re[power]);
                }
                double log_scale = (n & 1 ? 1.0 : -1.0) / (double)n;
                double source_sign = (n & 1 ? -1.0 : 1.0);
                local_re[target][n] += multipole_re[source][0] * log_scale * inv_re[n] - source_sign * sum_re;
                local_im[target][n] += multipole_re[source][0] * log_scale * inv_im[n] - source_sign * sum_im;
            }
        }
    }

    for (size_t i = 0; i < count; ++i) {
        int b = box[i], bx = b % 4, by = b / 4;
        double wr = x[i] - (2.0 * bx + 1.0), wi = y[i] - (2.0 * by + 1.0);
        double pr = 1.0, pi = 0.0;
        double value = local_re[b][0];
        for (int n = 1; n <= ORDER; ++n) {
            double next_re = pr * wr - pi * wi;
            double next_im = pr * wi + pi * wr;
            pr = next_re; pi = next_im;
            value += local_re[b][n] * pr - local_im[b][n] * pi;
        }
        for (size_t j = 0; j < count; ++j) {
            if (j == i) continue;
            int sb = box[j], sx = sb % 4, sy = sb / 4;
            if (abs(bx - sx) > 1 || abs(by - sy) > 1) continue;
            double dx = x[j] - x[i], dy = y[j] - y[i];
            value += charge[j] * 0.5 * log(dx * dx + dy * dy);
        }
        output[i] = value;
    }
    return (int64_t)count;
}
