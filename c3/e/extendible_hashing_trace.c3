module extendible_hashing_trace;

import "core:c";

const usz N = 256;
const usz MAX_OPS = 40;
const usz MAX_WORDS = 82;

struct Table {
    uint[N] directory;
    uint[N][2] keys;
    uint[N] counts;
    uint[N] depths;
    bool[N] active;
    usz gd;
    usz high;
    usz buckets;
    usz live;
}

fn usz bucket_for(Table* t, usz key) {
    return (usz)t.directory[key & ((1 << t.gd) - 1)];
}

fn long find_slot(Table* t, usz bucket, usz key) {
    for (usz s = 0; s < (usz)t.counts[bucket]; s++) if ((usz)t.keys[bucket][s] == key) return (long)s;
    return -1;
}

fn bool split(Table* t, usz bucket) {
    usz depth = (usz)t.depths[bucket];
    if (depth >= 8) return false;
    if (depth == t.gd) {
        usz old_size = 1 << t.gd;
        for (usz i = 0; i < old_size; i++) t.directory[i + old_size] = t.directory[i];
        t.gd++;
        if (t.gd > t.high) t.high = t.gd;
    }
    usz fresh = 0;
    while (fresh < N && t.active[fresh]) fresh++;
    if (fresh == N) return false;
    t.active[fresh] = true;
    t.depths[bucket] = (uint)(depth + 1); t.depths[fresh] = (uint)(depth + 1);
    usz old_count = (usz)t.counts[bucket];
    uint[2] old_keys = t.keys[bucket];
    t.counts[bucket] = 0; t.counts[fresh] = 0;
    t.keys[bucket][0] = 0; t.keys[bucket][1] = 0;
    t.keys[fresh][0] = 0; t.keys[fresh][1] = 0;
    usz bit = 1 << depth; usz size = 1 << t.gd;
    for (usz i = 0; i < size; i++) if ((usz)t.directory[i] == bucket && (i & bit) != 0) t.directory[i] = (uint)fresh;
    for (usz i = 0; i < old_count; i++) {
        usz key = (usz)old_keys[i]; usz target = bucket;
        if ((key & bit) != 0) target = fresh;
        t.keys[target][(usz)t.counts[target]] = (uint)key;
        t.counts[target]++;
    }
    t.buckets++;
    return true;
}

fn void coalesce(Table* t, usz start) {
    usz bucket = start;
    while ((usz)t.depths[bucket] > 1) {
        usz depth = (usz)t.depths[bucket]; usz size = 1 << t.gd;
        long representative = -1;
        for (usz i = 0; i < size; i++) if ((usz)t.directory[i] == bucket) { representative = (long)i; break; }
        if (representative < 0) break;
        usz prefix = ((usz)representative) & ((1 << depth) - 1);
        usz buddy_prefix = prefix ^ (1 << (depth - 1)); usz buddy = (usz)t.directory[buddy_prefix];
        if (buddy == bucket || !t.active[buddy] || (usz)t.depths[buddy] != depth || t.counts[bucket] + t.counts[buddy] > 2) break;
        usz keep = bucket; usz drop = buddy;
        if (buddy_prefix < prefix) { keep = buddy; drop = bucket; }
        usz keep_count = (usz)t.counts[keep]; usz drop_count = (usz)t.counts[drop];
        for (usz j = 0; j < drop_count; j++) t.keys[keep][keep_count + j] = t.keys[drop][j];
        t.counts[keep] += t.counts[drop]; t.counts[drop] = 0;
        t.keys[drop][0] = 0; t.keys[drop][1] = 0;
        t.depths[keep] = (uint)(depth - 1); t.active[drop] = false;
        for (usz i = 0; i < size; i++) if ((usz)t.directory[i] == drop) t.directory[i] = (uint)keep;
        t.buckets--; bucket = keep;
    }
    while (t.gd > 1) {
        usz half = 1 << (t.gd - 1); bool mirror = true;
        for (usz i = 0; i < half; i++) if (t.directory[i] != t.directory[i + half]) { mirror = false; break; }
        if (!mirror) break;
        t.gd--;
    }
}

fn long extendible_hashing_trace(long* input, usz length) @export("extendible_hashing_trace") {
    if (input == null || length < 1 || length > MAX_WORDS) return -1;
    long q_value = input[0];
    if (q_value < 0 || q_value > (long)MAX_OPS || length != (usz)(1 + 2 * q_value)) return -1;
    usz q = (usz)q_value;
    for (usz i = 0; i < q; i++) if (input[1 + 2 * i] < 0 || input[1 + 2 * i] > 2 || input[2 + 2 * i] < 0 || input[2 + 2 * i] > 255) return -1;
    Table t;
    for (usz i = 0; i < N; i++) {
        t.directory[i] = 0; t.counts[i] = 0; t.depths[i] = 0; t.active[i] = false;
        t.keys[i][0] = 0; t.keys[i][1] = 0;
    }
    t.directory[0] = 0; t.directory[1] = 1; t.active[0] = true; t.active[1] = true;
    t.depths[0] = 1; t.depths[1] = 1; t.gd = 1; t.high = 1; t.buckets = 2; t.live = 0;
    ulong successes = 0;
    for (usz i = 0; i < q; i++) {
        usz op = (usz)input[1 + 2 * i]; usz key = (usz)input[2 + 2 * i];
        usz bucket = bucket_for(&t, key); long slot = find_slot(&t, bucket, key); ulong success = 0;
        if (op == 0 && slot < 0) {
            while (t.counts[bucket] == 2) { if (!split(&t, bucket)) break; bucket = bucket_for(&t, key); }
            if (t.counts[bucket] < 2) { t.keys[bucket][(usz)t.counts[bucket]] = (uint)key; t.counts[bucket]++; t.live++; success = 1; }
        } else if (op == 1 && slot >= 0) {
            t.counts[bucket]--;
            t.keys[bucket][(usz)slot] = t.keys[bucket][(usz)t.counts[bucket]];
            t.keys[bucket][(usz)t.counts[bucket]] = 0;
            t.live--; success = 1; coalesce(&t, bucket);
        } else if (op == 2 && slot >= 0) success = 1;
        successes = (successes << 1) | success;
    }
    return (long)(successes | ((ulong)t.buckets << 40) | ((ulong)t.gd << 49) | ((ulong)t.high << 53) | ((ulong)t.live << 57));
}
