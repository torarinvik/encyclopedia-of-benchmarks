module quadratic_probing_hash_table;

const usz MAX_OPERATIONS = 24;
const usz MAX_INITIAL_CAPACITY = 8;
const usz MAX_TABLE_CAPACITY = 64;
const usz MAX_INPUT_LENGTH = 51;
const usz MAX_INSERTS_TO_CAPACITY_64 = MAX_TABLE_CAPACITY / 4;
const usz MAX_OUTPUT_ELEMENTS = 3 + (MAX_OPERATIONS - MAX_INSERTS_TO_CAPACITY_64) + MAX_TABLE_CAPACITY;
const usz MAX_OUTPUT_BYTES = 8 * MAX_OUTPUT_ELEMENTS;

const long OP_INSERT = 0;
const long OP_REMOVE = 1;
const long OP_FIND = 2;

fn long probe_insert(long* slots, usz capacity, long key) {
    for (usz probe = 0; probe < capacity * 100; probe++) {
        // The benchmark normatively defines hash(key)=key.
        usz index = (usz)((key + (long)(probe * probe)) % (long)capacity);
        if (slots[index] == 0 || slots[index] == -1) return (long)index;
    }
    return -1L;
}

fn long probe_find(long* slots, usz capacity, long key) {
    for (usz probe = 0; probe < capacity * 100; probe++) {
        usz index = (usz)((key + (long)(probe * probe)) % (long)capacity);
        long slot = slots[index];
        if (slot == 0) return -1L;
        if (slot == key) return (long)index;
    }
    return -1L;
}

fn bool insert_key(long* slots, usz* capacity, usz* size, long key);
fn bool rehash(long* slots, usz* capacity, usz* size);

fn bool rehash(long* slots, usz* capacity, usz* size) {
    usz old_capacity = capacity[0];
    if (old_capacity > MAX_TABLE_CAPACITY / 2) return false;

    long[MAX_TABLE_CAPACITY] old_slots = zeroed;
    for (usz index = 0; index < old_capacity; index++) old_slots[index] = slots[index];

    usz new_capacity = old_capacity * 2;
    for (usz index = 0; index < new_capacity; index++) slots[index] = 0;
    capacity[0] = new_capacity;

    // Reinsertion follows add(), which can recursively trigger rehash again.
    for (usz index = 0; index < old_capacity; index++) {
        long key = old_slots[index];
        if (key == 0 || key == -1) continue;
        if (size[0] == 0) return false;
        size[0]--;
        if (!insert_key(slots, capacity, size, key)) return false;
    }
    return true;
}

fn bool insert_key(long* slots, usz* capacity, usz* size, long key) {
    long index = probe_insert(slots, capacity[0], key);
    if (index < 0) return false;
    slots[(usz)index] = key;
    size[0]++;
    if (size[0] * 2 >= capacity[0]) return rehash(slots, capacity, size);
    return true;
}

fn void write_i64_le(uint8* output, usz* offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset[0]] = (uint8)(bits & 255);
        bits >>= 8;
        offset[0]++;
    }
}

fn long quadratic_probing_hash_table(long* values, usz length, uint8* output, usz output_capacity)
    @export("quadratic_probing_hash_table") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1L;
    if (values[0] < 1 || values[0] > (long)MAX_INITIAL_CAPACITY ||
        values[1] < 0 || values[1] > (long)MAX_OPERATIONS) return -1L;

    usz capacity = (usz)values[0];
    usz operation_count = (usz)values[1];
    if (length != 2 + 2 * operation_count) return -1L;

    long[MAX_TABLE_CAPACITY] slots = zeroed;
    bool[MAX_TABLE_CAPACITY + 1] active = zeroed;
    long[MAX_OPERATIONS] find_results = zeroed;
    usz size = 0;
    usz find_count = 0;

    for (usz operation_index = 0; operation_index < operation_count; operation_index++) {
        long operation = values[2 + 2 * operation_index];
        long key = values[3 + 2 * operation_index];
        if (operation < OP_INSERT || operation > OP_FIND || key < 1 || key > 64) return -1L;
        usz key_index = (usz)key;

        if (operation == OP_INSERT) {
            if (active[key_index]) return -1L;
            if (!insert_key(&slots[0], &capacity, &size, key)) return -1L;
            active[key_index] = true;
        } else if (operation == OP_REMOVE) {
            if (!active[key_index]) return -1L;
            long index = probe_find(&slots[0], capacity, key);
            if (index < 0) return -1L;
            slots[(usz)index] = -1;
            active[key_index] = false;
            size--;
        } else {
            long index = probe_find(&slots[0], capacity, key);
            // Source find() uses index zero as its not-present sentinel.
            find_results[find_count++] = index <= 0 ? 0 : slots[(usz)index];
        }
    }

    usz output_elements = 3 + find_count + capacity;
    usz output_bytes = output_elements * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1L;
    if (output == null || output_capacity < output_bytes) return -2L;

    usz offset = 0;
    write_i64_le(output, &offset, (long)capacity);
    write_i64_le(output, &offset, (long)size);
    write_i64_le(output, &offset, (long)find_count);
    for (usz index = 0; index < find_count; index++)
        write_i64_le(output, &offset, find_results[index]);
    for (usz index = 0; index < capacity; index++)
        write_i64_le(output, &offset, slots[index]);
    return (long)offset;
}
