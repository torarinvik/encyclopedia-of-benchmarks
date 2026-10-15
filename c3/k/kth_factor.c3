module kth_factor;

fn long kth_factor(long n_value, long k_value) @export("kth_factor")
{
    if (n_value < 1 || n_value > 10000 || k_value < 1 || k_value > n_value) return -1L;
    int n = (int)n_value;
    int k = (int)k_value;
    int factors_found = 0;
    for (int i = 1; i <= n; i++) {
        if (n % i == 0) {
            factors_found++;
            if (factors_found == k) return (long)i;
        }
    }
    return -1L;
}
