module optimal_mismatch;

fn long optimal_mismatch(long* values, usz length) @export("optimal_mismatch") {
    if (values == null || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16) return -2;
    usz n = (usz)values[0];
    usz m = (usz)values[1];
    if (length != 2 + n + m) return -2;
    usz pattern_start = 2 + n;
    for (usz i = 0; i < n + m; i++) {
        if (values[2 + i] < 0 || values[2 + i] > 127) return -2;
    }
    if (m > n) return -1;

    usz[128] frequency;
    for (usz i = 0; i < 128; i++) frequency[i] = 0;
    for (usz i = 0; i < n; i++) frequency[(usz)values[2 + i]]++;
    usz[16] order;
    for (usz i = 0; i < m; i++) order[i] = i;
    for (usz i = 1; i < m; i++) {
        usz selected = order[i];
        usz cursor = i;
        while (cursor > 0) {
            usz previous = order[cursor - 1];
            usz pf = frequency[(usz)values[pattern_start + previous]];
            usz sf = frequency[(usz)values[pattern_start + selected]];
            if (pf < sf || (pf == sf && previous > selected)) break;
            order[cursor] = previous;
            cursor--;
        }
        order[cursor] = selected;
    }

    usz[128] quick_shift;
    for (usz byte = 0; byte < 128; byte++) quick_shift[byte] = m + 1;
    for (usz i = 0; i < m; i++) quick_shift[(usz)values[pattern_start + i]] = m - i;

    usz[16] adapted_shift;
    for (usz rank = 0; rank < m; rank++) {
        adapted_shift[rank] = m;
        usz mismatch = order[rank];
        for (usz shift = 1; shift <= m; shift++) {
            bool compatible = true;
            for (usz prior = 0; prior < rank; prior++) {
                usz position = order[prior];
                if (position >= shift && values[pattern_start + position] != values[pattern_start + position - shift]) {
                    compatible = false;
                    break;
                }
            }
            if (!compatible) continue;
            if (mismatch >= shift && values[pattern_start + mismatch - shift] == values[pattern_start + mismatch]) continue;
            adapted_shift[rank] = shift;
            break;
        }
    }

    usz start = 0;
    usz last_start = n - m;
    while (start <= last_start) {
        usz rank = 0;
        while (rank < m && values[2 + start + order[rank]] == values[pattern_start + order[rank]]) rank++;
        if (rank == m) return (long)start;
        if (start + m == n) break;
        usz quick = quick_shift[(usz)values[2 + start + m]];
        start += adapted_shift[rank] > quick ? adapted_shift[rank] : quick;
    }
    return -1;
}
