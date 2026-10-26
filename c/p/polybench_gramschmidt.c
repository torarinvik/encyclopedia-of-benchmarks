/* Clean-room bounded PolyBench QR port. See package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 6
#define MAX_CELLS 36
#define MAX_OUTPUT 72

int64_t polybench_gramschmidt(const double *input, size_t length,
                             double *output, size_t capacity) {
    if (input == NULL || length != 2 || !isfinite(input[0]) || !isfinite(input[1]) ||
        trunc(input[0]) != input[0] || trunc(input[1]) != input[1] ||
        input[0] < 1.0 || input[0] > MAX_SIDE || input[1] < 1.0 ||
        input[1] > MAX_SIDE || input[1] > input[0]) return -1;
    const size_t m = (size_t)input[0], n = (size_t)input[1];
    const size_t q_cells = m * n, r_cells = n * n, total = q_cells + r_cells;
    if (output == NULL || capacity < total) return -2;

    double a[MAX_CELLS] = {0.0}, q[MAX_CELLS] = {0.0}, r[MAX_CELLS] = {0.0};
    double staged[MAX_OUTPUT] = {0.0};
    for (size_t i = 0; i < m; ++i)
        for (size_t j = 0; j < n; ++j)
            a[i * n + j] = ((double)((i * j) % m) / (double)m) * 100.0 + 10.0;

    for (size_t k = 0; k < n; ++k) {
        double norm_squared = 0.0;
        for (size_t i = 0; i < m; ++i)
            norm_squared += a[i * n + k] * a[i * n + k];
        r[k * n + k] = sqrt(norm_squared);
        for (size_t i = 0; i < m; ++i)
            q[i * n + k] = a[i * n + k] / r[k * n + k];
        for (size_t j = k + 1; j < n; ++j) {
            r[k * n + j] = 0.0;
            for (size_t i = 0; i < m; ++i)
                r[k * n + j] += q[i * n + k] * a[i * n + j];
            for (size_t i = 0; i < m; ++i)
                a[i * n + j] = a[i * n + j] - q[i * n + k] * r[k * n + j];
        }
    }
    for (size_t x = 0; x < r_cells; ++x) staged[x] = r[x];
    for (size_t x = 0; x < q_cells; ++x) staged[r_cells + x] = q[x];
    for (size_t x = 0; x < total; ++x) output[x] = staged[x];
    return (int64_t)total;
}
