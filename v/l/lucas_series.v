module lucas_series
@[export: 'lucas_series']
pub fn lucas_series(n i64) i64 {
    if n < 0 || n > 90 { return -1 }
    if n == 0 { return 2 }
    mut previous := i64(2)
    mut current := i64(1)
    for index := i64(2); index <= n; index++ { next := previous + current; previous = current; current = next }
    return current
}
