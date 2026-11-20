module berry_ravindran_search;

fn long berry_ravindran_search(long* values, usz length) @export("berry_ravindran_search") {
    if (values == null || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16) return -2;
    usz n = (usz)values[0], m = (usz)values[1];
    if (length != 2 + n + m) return -2;
    for (usz i = 0; i < n + m; i++) if (values[2 + i] < 0 || values[2 + i] > 15) return -2;
    if (m > n) return -1;
    usz p = 2 + n;
    usz[289] shift;
    for (usz i = 0; i < 289; i++) shift[i] = m + 2;
    for (usz a = 0; a < 17; a++) shift[a * 17 + (usz)values[p]] = m + 1;
    for (usz i = 0; i + 1 < m; i++) shift[(usz)values[p + i] * 17 + (usz)values[p + i + 1]] = m - i;
    for (usz b = 0; b < 17; b++) shift[(usz)values[p + m - 1] * 17 + b] = 1;
    usz start = 0;
    while (start <= n - m) {
        usz i = 0;
        while (i < m && values[2 + start + i] == values[p + i]) i++;
        if (i == m) return (long)start;
        usz k = start + m;
        if (k >= n) break;
        usz first = (usz)values[2 + k];
        usz second = k + 1 < n ? (usz)values[2 + k + 1] : 16;
        start += shift[first * 17 + second];
    }
    return -1;
}
