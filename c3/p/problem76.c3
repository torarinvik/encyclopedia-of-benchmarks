module problem76;

const int MAX_TOTAL = 200;
const int MAX_PARTS = 200;
const int MEMO_SIZE = 40200;

fn long problem76(long total) @export("problem76") {
    if (total < 1 || total > MAX_TOTAL) return -1;
    long[MEMO_SIZE] memo = {0};
    for (int n = 0; n <= (int)total; ++n) memo[n * MAX_PARTS] = 1;
    for (int n = 0; n <= (int)total; ++n) {
        for (int k = 1; k < (int)total; ++k) {
            int index = n * MAX_PARTS + k;
            memo[index] += memo[index - 1];
            if (n > k) memo[index] += memo[(n - k - 1) * MAX_PARTS + k];
        }
    }
    return memo[(int)total * MAX_PARTS + (int)total - 1] - 1;
}
