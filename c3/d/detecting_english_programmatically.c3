module detecting_english_prog;

fn long detecting_english_programmatically(long* a, usz n) @export("detecting_english_programmatically") {
    if (a == null || n < 1 || n > 172) { return -1; }
    usz p = 0; long count = a[p++]; if (count < 0 || count > 8) { return -1; }
    usz starts[8]; usz lens[8];
    for (long w = 0; w < count; w++) {
        if (p >= n) { return -1; } long l = a[p++];
        if (l < 1 || l > 12 || p + (usz)l > n) { return -1; }
        starts[w] = p; lens[w] = (usz)l;
        for (usz j = 0; j < (usz)l; j++) { if (a[p+j] < 65 || a[p+j] > 90) { return -1; } }
        if (w > 0) {
            usz k = 0; while (k < lens[w-1] && k < lens[w] && a[starts[w-1]+k] == a[p+k]) { k++; }
            if (k == lens[w-1] && k == lens[w]) { return -1; }
            if (k == lens[w-1] && k < lens[w]) {} else if (k < lens[w-1] && k < lens[w] && a[starts[w-1]+k] > a[p+k]) { return -1; }
            else if (k < lens[w-1] && k == lens[w]) { return -1; }
        }
        p += (usz)l;
    }
    if (p >= n) { return -1; } long m = a[p++]; if (m < 1 || m > 64 || p + (usz)m + 2 != n) { return -1; }
    usz ms = p; for (usz j = 0; j < (usz)m; j++) { if (a[ms+j] < 0 || a[ms+j] > 127) { return -1; } }
    p += (usz)m; long wp = a[p++]; long lp = a[p++]; if (wp < 0 || wp > 100 || lp < 0 || lp > 100) { return -1; }
    long retained = 0; long tokens = 0; long hits = 0; usz i = 0; usz len = 0; long tok[64];
    while (i <= (usz)m) {
        long c = i < (usz)m ? a[ms+i] : 32; bool letter = (c >= 65 && c <= 90) || (c >= 97 && c <= 122); bool ws = c == 9 || c == 10 || c == 32;
        if (i < (usz)m && (letter || ws)) { retained++; }
        if (letter) { tok[len++] = c >= 97 ? c - 32 : c; i++; continue; }
        if (!ws) { i++; continue; }
        if (len == 0) { i++; continue; }
        tokens++;
        for (long w = 0; w < count; w++) { if (lens[w] != len) { continue; } usz k = 0; while (k < len && a[starts[w]+k] == tok[k]) { k++; } if (k == len) { hits++; break; } }
        len = 0; i++;
    }
    return tokens > 0 && hits * 100 >= wp * tokens && retained * 100 >= lp * m ? 1 : 0;
}
