module linear_probing_hash_map;

const usz MAX_OPS = 32, MAX_CAPACITY = 128, MAX_OUTPUT_WORDS = 320;

fn usz hash_index(long key, usz capacity) {
    return ((ulong)key & 0x7FFFFFFFUL) % capacity;
}

fn void resize_map(long* keys, long* values, bool* occupied, usz* capacity, usz new_capacity) {
    long old_keys[128], old_values[128];
    bool old_occupied[128];
    usz old_capacity = *capacity;
    for (usz i = 0; i < old_capacity; i++) {
        old_occupied[i] = occupied[i];
        if (old_occupied[i]) { old_keys[i] = keys[i]; old_values[i] = values[i]; }
    }
    *capacity = new_capacity;
    for (usz i = 0; i < new_capacity; i++) occupied[i] = false;
    for (usz i = 0; i < old_capacity; i++) {
        if (!old_occupied[i]) continue;
        usz index = hash_index(old_keys[i], new_capacity);
        while (occupied[index]) index = (index + 1) % new_capacity;
        keys[index] = old_keys[i]; values[index] = old_values[i]; occupied[index] = true;
    }
}

fn usz find_slot(long* keys, bool* occupied, usz capacity, long key) {
    usz index = hash_index(key, capacity);
    for (usz probe = 0; probe < capacity; probe++) {
        if (!occupied[index]) return capacity;
        if (keys[index] == key) return index;
        index = (index + 1) % capacity;
    }
    return capacity;
}

fn void put(long* keys, long* values, bool* occupied, usz* capacity, usz* size, long key, long value) {
    if (*size > *capacity / 2) resize_map(keys, values, occupied, capacity, *capacity * 2);
    usz index = hash_index(key, *capacity);
    while (occupied[index]) {
        if (keys[index] == key) { values[index] = value; return; }
        index = (index + 1) % *capacity;
    }
    keys[index] = key; values[index] = value; occupied[index] = true; *size += 1;
}

fn bool delete_key(long* keys, long* values, bool* occupied, usz* capacity, usz* size, long key) {
    usz index = find_slot(keys, occupied, *capacity, key);
    if (index == *capacity) return false;
    occupied[index] = false; values[index] = 0; index = (index + 1) % *capacity;
    while (occupied[index]) {
        long rehash_key = keys[index], rehash_value = values[index];
        occupied[index] = false; values[index] = 0; *size -= 1;
        put(keys, values, occupied, capacity, size, rehash_key, rehash_value);
        index = (index + 1) % *capacity;
    }
    *size -= 1;
    if (*size > 0 && *size <= *capacity / 8)
        resize_map(keys, values, occupied, capacity, *capacity / 2);
    return true;
}

fn void append(long* words, usz* count, long value) { words[*count] = value; *count += 1; }

long linear_probing_hash_map(long* input, usz length, char* output, usz output_capacity)
        @export("linear_probing_hash_map") {
    if (input == null || length < 2 || length > 98 || input[0] < 4 || input[0] > 16 ||
        input[1] < 0 || input[1] > (long)MAX_OPS) return -1;
    usz operation_count = (usz)input[1];
    if (length > 2 + 3 * operation_count) return -1;
    long keys[128], values[128], words[320];
    bool occupied[128];
    usz capacity = (usz)input[0], size = 0, word_count = 0, position = 2;
    for (usz i = 0; i < 64; i++) occupied[i] = false;
    for (usz opi = 0; opi < operation_count; opi++) {
        if (position >= length) return -1;
        long opcode = input[position++];
        if (opcode == 0) {
            if (position + 1 >= length) return -1;
            long key = input[position], value = input[position + 1]; position += 2;
            if (key < -2147483648L || key > 2147483647L || value < -2147483648L || value > 2147483647L) return -1;
            put(keys, values, occupied, &capacity, &size, key, value);
            append(words, &word_count, 0); append(words, &word_count, 1);
        } else if (opcode >= 1 && opcode <= 3) {
            if (position >= length) return -1;
            long key = input[position++];
            if (key < -2147483648L || key > 2147483647L) return -1;
            usz index = find_slot(keys, occupied, capacity, key);
            if (opcode == 1) {
                append(words, &word_count, 1);
                if (index == capacity) { append(words, &word_count, 1); append(words, &word_count, 0); }
                else { append(words, &word_count, 0); append(words, &word_count, values[index]); }
            } else if (opcode == 2) {
                append(words, &word_count, 2); append(words, &word_count, delete_key(keys, values, occupied, &capacity, &size, key) ? 1 : 0);
            } else {
                append(words, &word_count, 3); append(words, &word_count, index != capacity ? 1 : 0);
            }
        } else if (opcode == 4) {
            append(words, &word_count, 4); append(words, &word_count, (long)size);
        } else if (opcode == 5) {
            long sorted[32]; usz count = 0;
            for (usz i = 0; i < capacity; i++) if (occupied[i]) sorted[count++] = keys[i];
            for (usz i = 1; i < count; i++) {
                long value = sorted[i]; usz j = i;
                while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; j--; }
                sorted[j] = value;
            }
            append(words, &word_count, 5); append(words, &word_count, (long)count);
            for (usz i = 0; i < count; i++) append(words, &word_count, sorted[i]);
        } else return -1;
    }
    if (position != length || word_count > MAX_OUTPUT_WORDS) return -1;
    usz bytes = word_count * 8;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < word_count; i++) {
        ulong bits = (ulong)words[i];
        for (usz b = 0; b < 8; b++) output[8 * i + b] = (char)((bits >> (8 * b)) & 255);
    }
    return (long)bytes;
}
