#include <stddef.h>
#include <stdint.h>

enum { MAX_SIDE = 64, MAX_WIDTH = 8, MAX_AREA = 512, MAX_STATES = 1 << MAX_WIDTH };
static const int64_t MOD = 998244353;

int64_t broken_profile_domino_tilings(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    int64_t h0 = input[0], w0 = input[1];
    if (h0 < 1 || h0 > MAX_SIDE || w0 < 1 || w0 > MAX_SIDE ||
        (h0 < w0 ? h0 : w0) > MAX_WIDTH || h0 * w0 > MAX_AREA) return -1;
    size_t height = (size_t)(h0 > w0 ? h0 : w0);
    size_t width = (size_t)(h0 < w0 ? h0 : w0);
    size_t states = (size_t)1 << width, full = states - 1;
    int64_t dp[MAX_STATES] = {0}, next[MAX_STATES] = {0};
    dp[0] = 1;
    for (size_t row = 0; row < height; ++row) {
        for (size_t s = 0; s < states; ++s) next[s] = 0;
        for (size_t incoming = 0; incoming < states; ++incoming) if (dp[incoming]) {
            for (size_t outgoing = 0; outgoing < states; ++outgoing) {
                if ((incoming & outgoing) || (row + 1 == height && outgoing != 0)) continue;
                size_t free_cells = full & ~(incoming | outgoing), col = 0;
                int valid = 1;
                while (col < width) {
                    if ((free_cells >> col) & 1u) {
                        if (col + 1 >= width || ((free_cells >> (col + 1)) & 1u) == 0) { valid = 0; break; }
                        col += 2;
                    } else ++col;
                }
                if (valid) next[outgoing] = (next[outgoing] + dp[incoming]) % MOD;
            }
        }
        for (size_t s = 0; s < states; ++s) dp[s] = next[s];
    }
    return dp[0];
}
