module trinomial_triangle;

fn long trinomial_value(long n, long k) {
    if (n == 0 && k == 0) return 1;
    if (k < -n || k > n) return 0;
    return trinomial_value(n - 1, k - 1) +
           trinomial_value(n - 1, k) +
           trinomial_value(n - 1, k + 1);
}

fn long trinomial_triangle(long n, long k) @export("trinomial_triangle") {
    if (n < 0 || n > 10 || k < -10 || k > 10) return -1;
    return trinomial_value(n, k);
}
