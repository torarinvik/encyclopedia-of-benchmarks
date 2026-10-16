module double_hash_hash_table;

// Bounded double-hashing table: insert=1, search=2, delete=3.
fn long double_hash_hash_table(long* input, usz length) @export("double_hash_hash_table") {
    if (length < 2) return -1;
    long cap64 = input[0];
    long count = input[1];
    if (cap64 < 3 || cap64 > 101 || count < 0 || count > 512) return -1;
    usz cap = (usz)cap64;
    if (length != 2 + 2 * (usz)count) return -1;
    for (usz d = 2; d * d <= cap; d++) if (cap % d == 0) return -1;
    int[101] states;
    long[101] keys;
    long successes = 0;
    for (usz i = 0; i < (usz)count; i++) {
        long op = input[2 + 2 * i];
        long key = input[3 + 2 * i];
        if (op < 1 || op > 3) return -1;
        long first_mod = key % cap64;
        if (first_mod < 0) first_mod += cap64;
        usz first = (usz)first_mod;
        long step_mod = key % (cap64 - 1);
        if (step_mod < 0) step_mod += cap64 - 1;
        usz step = 1 + (usz)step_mod;
        if (op == 1) {
            usz tomb = cap;
            bool inserted = false;
            for (usz p = 0; p < cap; p++) {
                usz slot = (first + p * step) % cap;
                if (states[slot] == 1 && keys[slot] == key) { tomb = cap; break; }
                if (states[slot] == 2 && tomb == cap) tomb = slot;
                if (states[slot] == 0) {
                    usz target = tomb == cap ? slot : tomb;
                    states[target] = 1; keys[target] = key; inserted = true; break;
                }
            }
            if (!inserted && tomb != cap) { states[tomb] = 1; keys[tomb] = key; inserted = true; }
            if (inserted) successes++;
        } else {
            for (usz p = 0; p < cap; p++) {
                usz slot = (first + p * step) % cap;
                if (states[slot] == 0) break;
                if (states[slot] == 1 && keys[slot] == key) {
                    successes++;
                    if (op == 3) states[slot] = 2;
                    break;
                }
            }
        }
    }
    return successes;
}
