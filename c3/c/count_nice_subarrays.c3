module count_nice_subarrays;

const usz MAX_LENGTH = 4096;

fn long count_nice_subarrays(long* values, usz length) @export("count_nice_subarrays") {
    if (values == null || length < 2 || values[0] < 0 || values[0] > 4096 || values[1] < 1 || values[1] > 4096) return -1;
    int n = (int)values[0];
    int k = (int)values[1];
    if (length != (usz)(n + 2)) return -1;
    for (int i = 0; i < n; i++) if (values[i + 2] < -2147483648 || values[i + 2] > 2147483647) return -1;
    int[4096] memo;
    for (int i = 0; i < n; i++) {
        memo[i] = 0;
    }
    int left = 0;
    int odd_count = 0;
    long result = 0;
    for (int right = 0; right < n; right++) {
        if ((((int)values[right + 2]) & 1) == 1) odd_count++;
        if (odd_count > k) {
            left += memo[left];
            odd_count--;
        }
        if (odd_count == k) {
            if (memo[left] == 0) {
                int even_count = 0;
                int temp = left;
                while ((((int)values[temp + 2]) & 1) == 0) { even_count++; temp++; }
                memo[left] = even_count + 1;
            }
            result += memo[left];
        }
    }
    return result;
}
