module chaining;

fn long chaining(long* input, usz length) @export("chaining") {
    if (input == null || length < 2 || length > 260) return -1;
    long bucket_count_value = input[0];
    long operation_count_value = input[1];
    if (bucket_count_value < 1 || bucket_count_value > 127 || operation_count_value < 0 || operation_count_value > 128) return -1;
    usz bucket_count = (usz)bucket_count_value;
    usz operation_count = (usz)operation_count_value;
    if (length != 2 + 2 * operation_count) return -1;

    long[127] heads;
    long[128] keys;
    long[128] next;
    for (usz bucket = 0; bucket < bucket_count; bucket++) {
        heads[bucket] = -1;
    }
    usz inserted = 0;
    usz query_count = 0;
    long result = 0;
    for (usz operation_index = 0; operation_index < operation_count; operation_index++) {
        long operation = input[2 + 2 * operation_index];
        long key = input[3 + 2 * operation_index];
        if ((operation != 0 && operation != 1) || key < 0 || key > 2147483647) return -1;
        usz bucket = (usz)(key % bucket_count_value);
        if (operation == 0) {
            if (inserted >= 128) return -1;
            keys[inserted] = key;
            next[inserted] = -1;
            if (heads[bucket] < 0) {
                heads[bucket] = (long)inserted;
            } else {
                long node = heads[bucket];
                while (next[(usz)node] >= 0) node = next[(usz)node];
                next[(usz)node] = (long)inserted;
            }
            inserted++;
        } else {
            if (query_count >= 63) return -1;
            long node = heads[bucket];
            while (node >= 0 && keys[(usz)node] != key) node = next[(usz)node];
            if (node >= 0) result += 1l << query_count;
            query_count++;
        }
    }
    return result;
}
