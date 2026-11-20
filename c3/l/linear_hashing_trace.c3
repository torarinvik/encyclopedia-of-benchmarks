module linear_hashing_trace;

const usz MAX_OPERATIONS = 63;
const usz MAX_BUCKETS = 32;

fn usz bucket_index(long key, usz level, usz split) {
    usz base = (usz)1 << level;
    long remainder = key % (long)base;
    if (remainder < 0) remainder += (long)base;
    usz index = (usz)remainder;
    if (index < split) {
        remainder = key % (long)(base << 1);
        if (remainder < 0) remainder += (long)(base << 1);
        index = (usz)remainder;
    }
    return index;
}

fn long linear_hashing_trace(long* values, usz length) @export("linear_hashing_trace") {
    if (values == null || length < 1 || length > 128) return -1;
    long operation_count = values[0];
    if (operation_count < 0 || operation_count > (long)MAX_OPERATIONS
        || length != (usz)(1 + 2 * operation_count)) return -1;

    long[MAX_BUCKETS] heads;
    long[MAX_OPERATIONS] keys;
    long[MAX_OPERATIONS] links;
    for (usz bucket = 0; bucket < MAX_BUCKETS; bucket++) heads[bucket] = -1;

    usz level = 1;
    usz split = 0;
    usz live_count = 0;
    usz allocated = 0;
    long result = 0;

    for (usz operation = 0; operation < (usz)operation_count; operation++) {
        long opcode = values[1 + 2 * operation];
        long key = values[2 + 2 * operation];
        if (opcode < 0 || opcode > 2 || key < -1024 || key > 1023) return -1;

        usz bucket = bucket_index(key, level, split);
        long previous = -1;
        long node = heads[bucket];
        while (node != -1 && keys[(usz)node] != key) {
            previous = node;
            node = links[(usz)node];
        }
        bool found = node != -1;
        long succeeded = 0;

        if (opcode == 0 && !found) {
            node = (long)allocated;
            allocated += 1;
            keys[(usz)node] = key;
            links[(usz)node] = heads[bucket];
            heads[bucket] = node;
            live_count += 1;
            succeeded = 1;

            usz base = (usz)1 << level;
            usz bucket_count = base + split;
            if (bucket_count < MAX_BUCKETS && live_count > 2 * bucket_count) {
                usz old_bucket = split;
                usz new_bucket = base + split;
                long current = heads[old_bucket];
                heads[old_bucket] = -1;
                while (current != -1) {
                    long following = links[(usz)current];
                    long remainder = keys[(usz)current] % (long)(base << 1);
                    if (remainder < 0) remainder += (long)(base << 1);
                    if ((usz)remainder == new_bucket) {
                        links[(usz)current] = heads[new_bucket];
                        heads[new_bucket] = current;
                    } else {
                        links[(usz)current] = heads[old_bucket];
                        heads[old_bucket] = current;
                    }
                    current = following;
                }
                split += 1;
                if (split == base) {
                    level += 1;
                    split = 0;
                }
            }
        } else if (opcode == 1 && found) {
            if (previous == -1) heads[bucket] = links[(usz)node];
            else links[(usz)previous] = links[(usz)node];
            live_count -= 1;
            succeeded = 1;
        } else if (opcode == 2 && found) {
            succeeded = 1;
        }
        result = (result << 1) | succeeded;
    }
    return result;
}
