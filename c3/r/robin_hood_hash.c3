module robin_hood_hash;

const usz TABLE_CAPACITY = 16;
const usz MAX_ACTIVE_ENTRIES = 14;
const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_OPERATIONS;
const usz MAX_OUTPUT_BYTES = 8 * MAX_OPERATIONS;
const uint MAX_PROBE_DISTANCE = 64;
const ulong GOLDEN_RATIO = 0x9E3779B97F4A7C15ul;

struct Entry { uint key; uint value; uint psl; bool occupied; }

fn usz hash_key(uint key) {
    ulong product = (ulong)key * GOLDEN_RATIO;
    return (usz)((product >> 32) & (TABLE_CAPACITY - 1));
}

fn bool map_put(Entry* entries, usz* count, uint key, uint value) {
    if ((*count * 100) / TABLE_CAPACITY >= 90) return false;
    Entry entry = {.key = key, .value = value, .psl = 0, .occupied = true};
    usz index = hash_key(key);
    uint probes = 0;
    while (probes < MAX_PROBE_DISTANCE) {
        Entry* resident = &entries[index];
        if (!resident.occupied) {
            *resident = entry;
            *count = *count + 1;
            return true;
        }
        if (resident.key == key) { resident.value = value; return true; }
        if (entry.psl > resident.psl) {
            Entry temporary = *resident;
            *resident = entry;
            entry = temporary;
        }
        entry.psl += 1;
        index = (index + 1) & (TABLE_CAPACITY - 1);
        probes += 1;
    }
    return false;
}

fn long map_get(Entry* entries, uint key) {
    usz index = hash_key(key);
    uint psl = 0;
    while (psl < MAX_PROBE_DISTANCE) {
        Entry* resident = &entries[index];
        if (!resident.occupied) return -1;
        if (resident.key == key) return (long)resident.value;
        if (psl > resident.psl) return -1;
        index = (index + 1) & (TABLE_CAPACITY - 1);
        psl += 1;
    }
    return -1;
}

fn void map_backshift(Entry* entries, usz start) {
    usz index = start;
    for (usz iteration = 0; iteration < TABLE_CAPACITY; iteration += 1) {
        usz next = (index + 1) & (TABLE_CAPACITY - 1);
        if (!entries[next].occupied || entries[next].psl == 0) {
            entries[index].occupied = false;
            entries[index].psl = 0;
            return;
        }
        entries[index] = entries[next];
        entries[index].psl -= 1;
        index = next;
    }
}

fn bool map_remove(Entry* entries, usz* count, uint key) {
    usz index = hash_key(key);
    uint psl = 0;
    while (psl < MAX_PROBE_DISTANCE) {
        Entry* resident = &entries[index];
        if (!resident.occupied) return false;
        if (resident.key == key) {
            map_backshift(entries, index);
            *count = *count - 1;
            return true;
        }
        if (psl > resident.psl) return false;
        index = (index + 1) & (TABLE_CAPACITY - 1);
        psl += 1;
    }
    return false;
}

fn void map_clear(Entry* entries, usz* count) {
    for (usz index = 0; index < TABLE_CAPACITY; index += 1) {
        entries[index].occupied = false;
        entries[index].psl = 0;
    }
    *count = 0;
}

fn uint map_max_psl(Entry* entries) {
    uint maximum = 0;
    for (usz index = 0; index < TABLE_CAPACITY; index += 1)
        if (entries[index].occupied && entries[index].psl > maximum) maximum = entries[index].psl;
    return maximum;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long robin_hood_hash(long* input, usz length, char* output, usz capacity)
    @export("robin_hood_hash") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];
    if (length != 1 + 3 * operation_count) return -1;

    Entry[TABLE_CAPACITY] entries = zeroed;
    long[MAX_OPERATIONS] results;
    usz count = 0;
    for (usz operation = 0; operation < operation_count; operation += 1) {
        usz offset = 1 + 3 * operation;
        long opcode = input[offset];
        long raw_key = input[offset + 1];
        long raw_value = input[offset + 2];
        if (opcode == 0) {
            if (raw_key < 0 || raw_key > 4294967295L || raw_value < 100 || raw_value > 1000000) return -1;
            if (!map_put(&entries[0], &count, (uint)raw_key, (uint)raw_value)) return -1;
            if (count > MAX_ACTIVE_ENTRIES) return -1;
            results[operation] = -2;
        } else if (opcode == 1 || opcode == 2) {
            if (raw_key < 0 || raw_key > 4294967295L || raw_value != 0) return -1;
            uint key = (uint)raw_key;
            results[operation] = opcode == 1 ? map_get(&entries[0], key) : (map_remove(&entries[0], &count, key) ? 1 : 0);
        } else if (opcode >= 3 && opcode <= 7) {
            if (raw_key != 0 || raw_value != 0) return -1;
            if (opcode == 3) results[operation] = (long)count;
            else if (opcode == 4) results[operation] = (long)((count * 100) / TABLE_CAPACITY);
            else if (opcode == 5) results[operation] = (long)map_max_psl(&entries[0]);
            else if (opcode == 6) { map_clear(&entries[0], &count); results[operation] = -3; }
            else results[operation] = count == 0 ? 1 : 0;
        } else return -1;
    }

    usz output_bytes = operation_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged;
    for (usz operation = 0; operation < operation_count; operation += 1)
        put_i64_le(&staged[0], operation * 8, results[operation]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
