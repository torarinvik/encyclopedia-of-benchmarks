module binomial_coefficient;

// Calculate C(n, k) by updating one row of Pascal's triangle.
fn long binomial_coefficient(ulong n, ulong k) @export("binomial_coefficient")
{
    if (n > 66) return -1;
    if (k > n) return 0;
    if (k == 0) return 1;
    long[67] coefficients;
    for (usz index = 0; index < 67; index++) coefficients[index] = 0;
    coefficients[0] = 1;
    for (ulong row = 1; row <= n; row++) {
        ulong column = row < k ? row : k;
        while (column > 0) {
            coefficients[column] += coefficients[column - 1];
            column--;
        }
    }
    return coefficients[k];
}
