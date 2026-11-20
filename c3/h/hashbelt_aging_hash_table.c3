module hashbelt_aging_hash_table;

const usz HB_GENERATIONS = 4;
const usz HB_BUCKETS = 8;
const usz HB_KEYS = 32;
const usz HB_MAX_OPS = 64;
const usz HB_MAX_WORDS = 1 + 3 * HB_MAX_OPS + 1;
const long HB_MISS = -2147483648;

fn int hb_find_in_table(i16* heads, i16* keys, i16* links, int table, int key) {
    int node = heads[table * (int)HB_BUCKETS + key % (int)HB_BUCKETS];
    while (node >= 0) {
        int record = table * (int)HB_KEYS + node;
        if (keys[record] == (i16)key) return node;
        node = links[record];
    }
    return -1;
}

fn int hb_find(i16* heads, i16* keys, i16* links, int newest, int key, int* found_table) {
    for (int age = 0; age < (int)HB_GENERATIONS; age++) {
        int table = (newest + age) % (int)HB_GENERATIONS;
        int node = hb_find_in_table(heads, keys, links, table, key);
        if (node >= 0) { *found_table = table; return node; }
    }
    *found_table = -1;
    return -1;
}

fn void hb_put(i16* heads, i16* keys, i16* values, i16* links, i16* used,
               int newest, int key, int value) {
    int node = hb_find_in_table(heads, keys, links, newest, key);
    if (node >= 0) {
        values[newest * (int)HB_KEYS + node] = (i16)value;
        return;
    }
    for (node = 0; node < (int)HB_KEYS && keys[newest * (int)HB_KEYS + node] >= 0; node++) { }
    if (node >= (int)HB_KEYS) return;
    used[newest]++;
    int bucket = key % (int)HB_BUCKETS;
    int record = newest * (int)HB_KEYS + node;
    keys[record] = (i16)key;
    values[record] = (i16)value;
    links[record] = heads[newest * (int)HB_BUCKETS + bucket];
    heads[newest * (int)HB_BUCKETS + bucket] = (i16)node;
}

fn void hb_remove(i16* heads, i16* keys, i16* values, i16* links, i16* used,
                 int table, int key, int target) {
    int bucket = key % (int)HB_BUCKETS;
    int previous = -1;
    int node = heads[table * (int)HB_BUCKETS + bucket];
    while (node >= 0 && node != target) {
        previous = node;
        node = links[table * (int)HB_KEYS + node];
    }
    if (node < 0) return;
    if (previous < 0) heads[table * (int)HB_BUCKETS + bucket] = links[table * (int)HB_KEYS + node];
    else links[table * (int)HB_KEYS + previous] = links[table * (int)HB_KEYS + node];
    int record = table * (int)HB_KEYS + node;
    keys[record] = -1;
    values[record] = 0;
    links[record] = -1;
    used[table]--;
}

fn void hb_write(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (char)(bits >> (byte * 8));
}

fn long hashbelt_aging_hash_table(long* input, usz length, char* output, usz capacity)
    @export("hashbelt_aging_hash_table") {
    if (input == null || length < 1 || length > HB_MAX_WORDS) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)HB_MAX_OPS) return -1;
    usz count = (usz)count_value;
    if (length != 1 + 3 * count) return -1;
    for (usz op = 0; op < count; op++) {
        long opcode = input[1 + 3 * op];
        long key = input[2 + 3 * op];
        long argument = input[3 + 3 * op];
        if (opcode == 0) {
            if (key < 0 || key >= (long)HB_KEYS || argument < -1000 || argument > 1000) return -1;
        } else if (opcode == 1) {
            if (key < 0 || key >= (long)HB_KEYS || argument != 0) return -1;
        } else if (opcode == 2) {
            if (key != 0 || argument != 0) return -1;
        } else return -1;
    }
    usz required = count * 8;
    if (output == null || capacity < required) return -2;

    i16[HB_GENERATIONS * HB_BUCKETS] heads;
    i16[HB_GENERATIONS * HB_KEYS] keys = {0};
    i16[HB_GENERATIONS * HB_KEYS] values = {0};
    i16[HB_GENERATIONS * HB_KEYS] links = {0};
    i16[HB_GENERATIONS] used = {0};
    long[HB_MAX_OPS] trace = {0};
    for (usz index = 0; index < HB_GENERATIONS * HB_BUCKETS; index++) heads[index] = -1;
    for (usz index = 0; index < HB_GENERATIONS * HB_KEYS; index++) keys[index] = -1;
    int newest = 0;
    for (usz op = 0; op < count; op++) {
        int opcode = (int)input[1 + 3 * op];
        int key = (int)input[2 + 3 * op];
        int argument = (int)input[3 + 3 * op];
        if (opcode == 0) {
            int found_table;
            int node = hb_find(&heads[0], &keys[0], &links[0], newest, key, &found_table);
            trace[op] = found_table < 0 ? 1 : 0;
            if (found_table >= 0 && found_table != newest)
                hb_remove(&heads[0], &keys[0], &values[0], &links[0], &used[0], found_table, key, node);
            hb_put(&heads[0], &keys[0], &values[0], &links[0], &used[0], newest, key, argument);
        } else if (opcode == 1) {
            int found_table;
            int node = hb_find(&heads[0], &keys[0], &links[0], newest, key, &found_table);
            if (node < 0) trace[op] = HB_MISS;
            else {
                trace[op] = values[found_table * (int)HB_KEYS + node];
                if (found_table != newest) {
                    hb_remove(&heads[0], &keys[0], &values[0], &links[0], &used[0], found_table, key, node);
                    hb_put(&heads[0], &keys[0], &values[0], &links[0], &used[0], newest, key, (int)trace[op]);
                }
            }
        } else {
            int oldest = (newest + (int)HB_GENERATIONS - 1) % (int)HB_GENERATIONS;
            trace[op] = used[oldest];
            for (int bucket = 0; bucket < (int)HB_BUCKETS; bucket++) heads[oldest * (int)HB_BUCKETS + bucket] = -1;
            for (int slot = 0; slot < (int)HB_KEYS; slot++) keys[oldest * (int)HB_KEYS + slot] = -1;
            used[oldest] = 0;
            newest = oldest;
        }
    }
    for (usz op = 0; op < count; op++) hb_write(output, op, trace[op]);
    return (long)required;
}
