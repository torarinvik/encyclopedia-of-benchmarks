#include <stddef.h>
#include <stdint.h>
#define MAX_VERTICES 8
#define MAX_STATES 256
#define MAX_INPUT_LENGTH 65
int64_t hamiltonian_path_exists(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > MAX_INPUT_LENGTH || input[0] < 0 || input[0] > MAX_VERTICES) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + n * n) return -1;
    uint64_t routes[MAX_VERTICES] = {0};
    for (size_t row = 0; row < n; ++row) for (size_t col = 0; col < n; ++col) {
        const int64_t cell = input[1 + row * n + col];
        if (cell != 0 && cell != 1) return -1;
        if (cell == 1) routes[row] |= UINT64_C(1) << col;
    }
    uint8_t dp[MAX_STATES][MAX_VERTICES] = {{0}};
    for (size_t start = 0; start < n; ++start) dp[(size_t)1 << start][start] = 1;
    const size_t full = ((size_t)1 << n) - 1;
    for (size_t mask = 1; mask <= full; ++mask) for (size_t last = 0; last < n; ++last) {
        if (!dp[mask][last]) continue;
        for (size_t next = 0; next < n; ++next) { const size_t bit = (size_t)1 << next; if (!(mask & bit) && (routes[last] & bit)) dp[mask | bit][next] = 1; }
    }
    for (size_t last = 0; last < n; ++last) if (dp[full][last]) return 1;
    return 0;
}
