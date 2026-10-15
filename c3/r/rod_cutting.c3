module rod_cutting;

const long INVALID_RESULT = -1;
const long MAX_ROD_LENGTH = 30;
const long MAX_PRICE = 1000;

fn long rod_cutting(long* values, usz length) @export("rod_cutting") {
    if (values == null || length < 2) return INVALID_RESULT;
    long n_value = values[0];
    if (n_value < 1 || n_value > MAX_ROD_LENGTH) return INVALID_RESULT;
    usz n = (usz)n_value;
    if (length != n + 1) return INVALID_RESULT;
    for (usz i = 0; i < n; i++) {
        if (values[i + 1] < 1 || values[i + 1] > MAX_PRICE) return INVALID_RESULT;
    }
    long profit[31] = {0};
    for (usz rod = 1; rod <= n; rod++) {
        long best = 0;
        for (usz cut = 1; cut <= rod; cut++) {
            long candidate = values[cut] + profit[rod - cut];
            if (candidate > best) best = candidate;
        }
        profit[rod] = best;
    }
    return profit[n];
}
