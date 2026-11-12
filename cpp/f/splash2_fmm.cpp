#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstdlib>

namespace {
constexpr int MAX_PARTICLES = 48, BOXES = 16, ORDER = 32, INV_ORDER = 2 * ORDER;
}

extern "C" int64_t splash2_fmm(const double *input, std::size_t input_length,
                                double *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 7 || input_length > 1 + 3 * MAX_PARTICLES) return -1;
    const double requested_count = input[0];
    if (!(requested_count >= 2.0 && requested_count <= MAX_PARTICLES) ||
        requested_count != static_cast<double>(static_cast<int>(requested_count))) return -1;
    const std::size_t count = static_cast<std::size_t>(requested_count);
    if (input_length != 1 + 3 * count) return -1;
    double x[MAX_PARTICLES], y[MAX_PARTICLES], charge[MAX_PARTICLES];
    int box[MAX_PARTICLES];
    for (std::size_t i = 0; i < count; ++i) {
        const double px = input[1 + 3 * i], py = input[2 + 3 * i], q = input[3 + 3 * i];
        if (!(px >= 0.0 && px < 8.0) || px != static_cast<double>(static_cast<int>(px)) ||
            !(py >= 0.0 && py < 8.0) || py != static_cast<double>(static_cast<int>(py)) ||
            !(q >= -3.0 && q <= 3.0) || q != static_cast<double>(static_cast<int>(q))) return -1;
        x[i] = px; y[i] = py; charge[i] = q;
        box[i] = (static_cast<int>(py) / 2) * 4 + static_cast<int>(px) / 2;
        for (std::size_t j = 0; j < i; ++j)
            if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    if (output == nullptr || output_capacity < count) return -2;
    double mr[BOXES][ORDER + 1] = {}, mi[BOXES][ORDER + 1] = {};
    double lr[BOXES][ORDER + 1] = {}, li[BOXES][ORDER + 1] = {};
    for (std::size_t i = 0; i < count; ++i) {
        const int b = box[i], bx = b % 4, by = b / 4;
        const double zr = x[i] - (2.0 * bx + 1.0), zi = y[i] - (2.0 * by + 1.0);
        double pr = 1.0, pi = 0.0;
        mr[b][0] += charge[i];
        for (int k = 1; k <= ORDER; ++k) {
            const double nr = pr * zr - pi * zi, ni = pr * zi + pi * zr;
            pr = nr; pi = ni; mr[b][k] += charge[i] * pr; mi[b][k] += charge[i] * pi;
        }
    }
    for (int t = 0; t < BOXES; ++t) for (int s = 0; s < BOXES; ++s) {
        const int tx = t % 4, ty = t / 4, sx = s % 4, sy = s / 4;
        const int dxbox = tx - sx, dybox = ty - sy;
        if (std::abs(dxbox) <= 1 && std::abs(dybox) <= 1) continue;
        const double dx = 2.0 * dxbox, dy = 2.0 * dybox, r2 = dx * dx + dy * dy;
        double ir[INV_ORDER + 1] = {}, ii[INV_ORDER + 1] = {};
        ir[0] = 1.0; const double one_r = dx / r2, one_i = -dy / r2;
        for (int p = 1; p <= INV_ORDER; ++p) {
            ir[p] = ir[p - 1] * one_r - ii[p - 1] * one_i;
            ii[p] = ir[p - 1] * one_i + ii[p - 1] * one_r;
        }
        double a0 = mr[s][0] * 0.5 * std::log(r2);
        for (int k = 1; k <= ORDER; ++k) a0 -= (mr[s][k] * ir[k] - mi[s][k] * ii[k]) / k;
        lr[t][0] += a0;
        for (int n = 1; n <= ORDER; ++n) {
            double sr = 0.0, si = 0.0;
            for (int k = 1; k <= ORDER; ++k) {
                double choose = 1.0;
                for (int j = 1; j <= n; ++j) choose *= static_cast<double>(k + j - 1) / j;
                const double scale = choose / k; const int p = k + n;
                sr += scale * (mr[s][k] * ir[p] - mi[s][k] * ii[p]);
                si += scale * (mr[s][k] * ii[p] + mi[s][k] * ir[p]);
            }
            const double log_scale = (n & 1 ? 1.0 : -1.0) / n;
            const double source_sign = (n & 1 ? -1.0 : 1.0);
            lr[t][n] += mr[s][0] * log_scale * ir[n] - source_sign * sr;
            li[t][n] += mr[s][0] * log_scale * ii[n] - source_sign * si;
        }
    }
    for (std::size_t i = 0; i < count; ++i) {
        const int b = box[i], bx = b % 4, by = b / 4;
        const double wr = x[i] - (2.0 * bx + 1.0), wi = y[i] - (2.0 * by + 1.0);
        double pr = 1.0, pi = 0.0, value = lr[b][0];
        for (int n = 1; n <= ORDER; ++n) {
            const double nr = pr * wr - pi * wi, ni = pr * wi + pi * wr;
            pr = nr; pi = ni; value += lr[b][n] * pr - li[b][n] * pi;
        }
        for (std::size_t j = 0; j < count; ++j) {
            if (j == i) continue;
            const int sb = box[j], sx = sb % 4, sy = sb / 4;
            if (std::abs(bx - sx) > 1 || std::abs(by - sy) > 1) continue;
            const double dx = x[j] - x[i], dy = y[j] - y[i];
            value += charge[j] * 0.5 * std::log(dx * dx + dy * dy);
        }
        output[i] = value;
    }
    return static_cast<std::int64_t>(count);
}
