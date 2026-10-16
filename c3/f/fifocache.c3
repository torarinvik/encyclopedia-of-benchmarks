module fifocache;

fn long fifocache(long* a, usz n, char* o, usz cap) @export("fifocache") {
    if (a == null || n < 2 || n > 26) return -1;
    long c = a[0];
    long ops = a[1];
    if (c < 1 || c > 6 || ops < 0 || ops > 8 || n != 2 + 3 * (usz)ops) return -1;
    long[6] keys;
    long[6] vals;
    char[8] queries;
    usz size = 0;
    usz gets = 0;
    char hits = 0;
    char misses = 0;
    for (usz i = 0; i < (usz)ops; i++) {
        long op = a[2 + 3 * i];
        long key = a[3 + 3 * i];
        long value = a[4 + 3 * i];
        if (key < 0 || key > 15 || (op != 0 && op != 1)) return -1;
        if (op == 0) {
            if (value < 0 || value > 255) return -1;
            usz j = 0;
            while (j < size && keys[j] != key) j++;
            if (j < size) {
                for (usz t = j + 1; t < size; t++) {
                    keys[t - 1] = keys[t];
                    vals[t - 1] = vals[t];
                }
                size--;
            }
            if (size == (usz)c) {
                for (usz t = 1; t < size; t++) {
                    keys[t - 1] = keys[t];
                    vals[t - 1] = vals[t];
                }
                size--;
            }
            keys[size] = key;
            vals[size] = value;
            size++;
        } else {
            if (value != 0) return -1;
            usz j = 0;
            while (j < size && keys[j] != key) j++;
            if (j < size) {
                hits++;
                queries[gets] = (char)vals[j];
            } else {
                misses++;
                queries[gets] = (char)255;
            }
            gets++;
        }
    }
    usz need = 4 + gets + 2 * size;
    if (o == null || cap < need) return -2;
    o[0] = hits;
    o[1] = misses;
    o[2] = (char)size;
    o[3] = (char)gets;
    for (usz i = 0; i < gets; i++) o[4 + i] = queries[i];
    for (usz i = 0; i < size; i++) {
        o[4 + gets + 2 * i] = (char)keys[i];
        o[5 + gets + 2 * i] = (char)vals[i];
    }
    return (long)need;
}
