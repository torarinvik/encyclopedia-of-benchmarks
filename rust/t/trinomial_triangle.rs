fn trinomial_value(n: i64, k: i64) -> i64 {
    if n == 0 && k == 0 {
        return 1;
    }
    if k < -n || k > n {
        return 0;
    }
    trinomial_value(n - 1, k - 1)
        + trinomial_value(n - 1, k)
        + trinomial_value(n - 1, k + 1)
}

#[no_mangle]
pub extern "C" fn trinomial_triangle(n: i64, k: i64) -> i64 {
    if !(0..=10).contains(&n) || !(-10..=10).contains(&k) {
        return -1;
    }
    trinomial_value(n, k)
}
