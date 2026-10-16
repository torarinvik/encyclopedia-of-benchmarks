module hamiltonian_path_exists;
const usz MAX_VERTICES = 8;
const usz MAX_STATES = 256;
const usz MAX_INPUT_LENGTH = 65;
fn long hamiltonian_path_exists(long* input, usz length) @export("hamiltonian_path_exists") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > (long)MAX_VERTICES) return -1;
    usz n = (usz)input[0];
    if (length != 1 + n * n) return -1;
    ulong[MAX_VERTICES] routes;
    for (usz row = 0; row < MAX_VERTICES; row++) routes[row] = 0;
    for (usz row = 0; row < n; row++) for (usz col = 0; col < n; col++) {
        long cell = input[1 + row * n + col];
        if (cell != 0 && cell != 1) return -1;
        if (cell == 1) routes[row] |= 1UL << col;
    }
    bool[MAX_STATES * MAX_VERTICES] dp;
    for (usz i = 0; i < MAX_STATES * MAX_VERTICES; i++) dp[i] = false;
    for (usz start = 0; start < n; start++) dp[((usz)1 << start) * MAX_VERTICES + start] = true;
    usz full = ((usz)1 << n) - 1;
    for (usz mask = 1; mask <= full; mask++) for (usz last = 0; last < n; last++) {
        if (!dp[mask * MAX_VERTICES + last]) continue;
        for (usz next = 0; next < n; next++) { usz bit = (usz)1 << next; if (!(mask & bit) && (routes[last] & (1UL << next)) != 0) dp[(mask | bit) * MAX_VERTICES + next] = true; }
    }
    for (usz last = 0; last < n; last++) if (dp[full * MAX_VERTICES + last]) return 1;
    return 0;
}
