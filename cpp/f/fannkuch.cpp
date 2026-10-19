/* Bounded port of the Benchmark Game fannkuch counter traversal. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t fannkuch(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length != 1 || values[0] < 1 || values[0] > 8) return -1;
    const int n = static_cast<int>(values[0]);
    int perm[8] = {}, perm1[8] = {}, count[8] = {};
    for (int i = 0; i < n; ++i) perm1[i] = i;
    int r = n, flips_max = 0;
    for (;;) {
        while (r != 1) { count[r - 1] = r; --r; }
        if (perm1[0] != 0 && perm1[n - 1] != n - 1) {
            for (int i = 1; i < n; ++i) perm[i] = perm1[i];
            int k = perm1[0], flips = 0;
            do {
                for (int i = 1, j = k - 1; i < j; ++i, --j) {
                    const int tmp = perm[i]; perm[i] = perm[j]; perm[j] = tmp;
                }
                ++flips;
                const int j = perm[k]; perm[k] = k; k = j;
            } while (k != 0);
            if (flips_max < flips) flips_max = flips;
        }
        for (;;) {
            if (r == n) return flips_max;
            const int first = perm1[0];
            for (int i = 0; i < r; ++i) perm1[i] = perm1[i + 1];
            perm1[r] = first;
            if (--count[r] > 0) break;
            ++r;
        }
    }
}
