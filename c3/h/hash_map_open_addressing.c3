module hash_map_open_addressing;

const usz MAX_OPERATIONS = 256;
const usz MAX_KEYS = 64;
const usz MAX_CAPACITY = 1024;
const usz MAX_INPUT_LENGTH = 769;
const long VALUE_OFFSET = 1000001;

struct Entry { int state; long key; long value; }

fn void place(Entry* table, usz capacity, long key, long value) {
    usz index = (usz)(key % (long)capacity);
    for (usz probe = 0; probe < capacity; probe++) {
        if (table[index].state != 1) { table[index] = {1, key, value}; return; }
        if (table[index].key == key) { table[index].value = value; return; }
        index = (index + 1) % capacity;
    }
}

fn void resize_table(Entry* table, usz* capacity, usz next, usz* size) {
    Entry[MAX_CAPACITY] old;
    usz old_capacity = *capacity;
    for (usz i = 0; i < old_capacity; i++) old[i] = table[i];
    for (usz i = 0; i < next; i++) table[i] = {0, 0, 0};
    *capacity = next; *size = 0;
    for (usz i = 0; i < old_capacity; i++) {
        if (old[i].state == 1) { place(table, next, old[i].key, old[i].value); *size += 1; }
    }
}

fn usz find_key(Entry* table, usz capacity, long key, usz* tombstone, bool* tomb_before) {
    usz index = (usz)(key % (long)capacity);
    *tombstone = capacity; *tomb_before = false;
    for (usz probe = 0; probe < capacity; probe++) {
        if (table[index].state == 0) return capacity;
        if (table[index].state == 2) { if (*tombstone == capacity) *tombstone = index; }
        else if (table[index].key == key) { *tomb_before = *tombstone != capacity; return index; }
        index = (index + 1) % capacity;
    }
    return capacity;
}

fn long hash_map_open_addressing(long* input, usz length) @export("hash_map_open_addressing") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long q = input[0];
    if (q < 0 || q > (long)MAX_OPERATIONS || length != 1 + 3 * (usz)q) return -1;
    Entry[MAX_CAPACITY] table;
    for (usz i = 0; i < MAX_CAPACITY; i++) table[i] = {0, 0, 0};
    usz capacity = 8, size = 0;
    long query_sum = 0, query_index = 0;
    for (usz opi = 0; opi < (usz)q; opi++) {
        long opcode = input[1 + 3 * opi], key = input[2 + 3 * opi], value = input[3 + 3 * opi];
        if (opcode == 0) {
            if (key < 0 || key > 1000000 || value < -1000000 || value > 1000000) return -1;
            usz tomb; bool tomb_before;
            usz before = find_key(&table[0], capacity, key, &tomb, &tomb_before);
            if (before == capacity && size >= MAX_KEYS) return -1;
            if (size >= capacity * 3 / 4) {
                if (capacity * 2 > MAX_CAPACITY) return -1;
                resize_table(&table[0], &capacity, capacity * 2, &size);
            }
            usz found = find_key(&table[0], capacity, key, &tomb, &tomb_before);
            if (found != capacity) {
                if (tomb_before) return -1;
                table[found].value = value;
            } else {
                usz index = (usz)(key % (long)capacity), target = tomb;
                for (usz probe = 0; probe < capacity; probe++) {
                    if (table[index].state == 0) { if (target == capacity) target = index; break; }
                    index = (index + 1) % capacity;
                }
                if (target == capacity) return -1;
                table[target] = {1, key, value}; size += 1;
            }
        } else if (opcode == 1 || opcode == 2 || opcode == 3) {
            if (key < 0 || key > 1000000 || value != 0) return -1;
            usz tomb; bool tomb_before;
            usz found = find_key(&table[0], capacity, key, &tomb, &tomb_before);
            if ((opcode == 1 || opcode == 2) && found == capacity) return -1;
            if (opcode == 1) { query_index += 1; query_sum += query_index * (table[found].value + VALUE_OFFSET); }
            else if (opcode == 2) {
                table[found].state = 2; size -= 1;
                if (capacity > 8 && size < capacity * 3 / 8) resize_table(&table[0], &capacity, capacity / 2, &size);
            } else { query_index += 1; query_sum += query_index * ((found != capacity ? 1 : 0) + VALUE_OFFSET); }
        } else if (opcode == 4) {
            if (key != 0 || value != 0) return -1;
            query_index += 1; query_sum += query_index * ((long)size + VALUE_OFFSET);
        } else return -1;
    }
    long keys[MAX_KEYS], values[MAX_KEYS]; usz count = 0;
    for (usz i = 0; i < capacity; i++) if (table[i].state == 1) {
        usz at = count; count += 1;
        while (at > 0 && keys[at - 1] > table[i].key) { keys[at] = keys[at - 1]; values[at] = values[at - 1]; at -= 1; }
        keys[at] = table[i].key; values[at] = table[i].value;
    }
    long final_state = 0;
    for (usz i = 0; i < count; i++) final_state += (long)(i + 1) * (keys[i] + 1) * (values[i] + VALUE_OFFSET);
    return query_sum + final_state + (long)size;
}
