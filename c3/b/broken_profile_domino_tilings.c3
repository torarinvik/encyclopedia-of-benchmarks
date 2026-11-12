module broken_profile_domino_tilings;
const usz MAX_STATES = 256;
const long MOD = 998244353;

fn long broken_profile_domino_tilings(long *input, usz length)
    @export("broken_profile_domino_tilings") {
    if (input == null || length != 2) return -1;
    long h0 = input[0], w0 = input[1];
    if (h0 < 1 || h0 > 64 || w0 < 1 || w0 > 64 || (h0 < w0 ? h0 : w0) > 8 || h0 * w0 > 512) return -1;
    usz height = (usz)(h0 > w0 ? h0 : w0), width = (usz)(h0 < w0 ? h0 : w0);
    usz states = (usz)1 << width, full = states - 1;
    long[256] dp, next; for (usz s = 0; s < 256; s++) { dp[s] = 0; next[s] = 0; } dp[0] = 1;
    for (usz row = 0; row < height; row++) {
        for (usz s = 0; s < states; s++) next[s] = 0;
        for (usz incoming = 0; incoming < states; incoming++) if (dp[incoming] != 0) {
            for (usz outgoing = 0; outgoing < states; outgoing++) {
                if ((incoming & outgoing) != 0 || (row + 1 == height && outgoing != 0)) continue;
                usz free_cells = full & ~(incoming | outgoing), col = 0; bool valid = true;
                while (col < width) {
                    if (((free_cells >> col) & 1) != 0) {
                        if (col + 1 >= width || ((free_cells >> (col + 1)) & 1) == 0) { valid = false; break; }
                        col += 2;
                    } else col++;
                }
                if (valid) next[outgoing] = (next[outgoing] + dp[incoming]) % MOD;
            }
        }
        for (usz s = 0; s < states; s++) dp[s] = next[s];
    }
    return dp[0];
}
