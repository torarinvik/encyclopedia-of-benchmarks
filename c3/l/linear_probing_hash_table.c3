module linear_probing_hash_table;

const usz MAX_TABLE_CAPACITY = 128, MAX_OPERATIONS = 32, MAX_INPUT_LENGTH = 66;
const usz MAX_OUTPUT_WORDS = 1088;
const long MAX_KEY = 2147483520L;

fn long find_slot(long* table, usz capacity, long key) {
    usz index = (usz)key % capacity;
    for (usz probe = 0; probe < capacity; probe++) {
        if (table[index] == 0) return -1;
        if (table[index] == key) return (long)index;
        index = (index + 1) % capacity;
    }
    return -1;
}

fn long insertion_slot(long* table, usz capacity, long key) {
    usz index = (usz)key % capacity;
    for (usz probe = 0; probe < capacity; probe++) {
        if (table[index] == 0 || table[index] == -1) return (long)index;
        index = (index + 1) % capacity;
    }
    return -1;
}

fn void rehash(long* table, usz* capacity) {
    long old_table[128];
    usz old_capacity = *capacity;
    for (usz i = 0; i < old_capacity; i++) old_table[i] = table[i];
    *capacity *= 2;
    for (usz i = 0; i < *capacity; i++) table[i] = 0;
    for (usz i = 0; i < old_capacity; i++) {
        long key = old_table[i];
        if (key <= 0) continue;
        long slot = insertion_slot(table, *capacity, key);
        if (slot >= 0) table[(usz)slot] = key;
    }
}

fn void append(long* words, usz* count, long value) {
    words[*count] = value;
    *count += 1;
}

fn long linear_probing_hash_table(long* input, usz length, char* output, usz output_capacity)
        @export("linear_probing_hash_table") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > 16 || input[1] < 0 || input[1] > (long)MAX_OPERATIONS) return -1;
    usz table_capacity = (usz)input[0], operation_count = (usz)input[1];
    long table[128] = {0};
    long words[MAX_OUTPUT_WORDS];
    usz size = 0, word_count = 0, position = 2;
    for (usz operation = 0; operation < operation_count; operation++) {
        if (position >= length) return -1;
        long opcode = input[position++];
        if (opcode >= 0 && opcode <= 3) {
            if (position >= length) return -1;
            long key = input[position++];
            if (key < 1 || key > MAX_KEY) return -1;
            if (opcode == 0) {
                long slot = insertion_slot(table, table_capacity, key);
                if (slot < 0) return -1;
                table[(usz)slot] = key; size++;
                append(words, &word_count, 0); append(words, &word_count, 1);
                if (size * 2 >= table_capacity) rehash(table, &table_capacity);
            } else if (opcode == 1) {
                long slot = find_slot(table, table_capacity, key);
                if (slot < 0) return -1;
                table[(usz)slot] = -1; size--;
                append(words, &word_count, 1); append(words, &word_count, 1);
            } else if (opcode == 2) {
                append(words, &word_count, 2);
                append(words, &word_count, find_slot(table, table_capacity, key) >= 0 ? 1 : 0);
            } else {
                append(words, &word_count, 3); append(words, &word_count, key);
            }
        } else if (opcode == 4) {
            append(words, &word_count, 4); append(words, &word_count, (long)table_capacity);
            for (usz i = 0; i < table_capacity; i++) append(words, &word_count, table[i] == 0 ? -2 : table[i]);
        } else return -1;
    }
    if (position != length || word_count > MAX_OUTPUT_WORDS) return -1;
    usz bytes = word_count * 8;
    if (output == null || output_capacity < bytes) return -2;
    for (usz i = 0; i < word_count; i++) {
        ulong bits = (ulong)words[i];
        for (usz byte = 0; byte < 8; byte++) output[8*i+byte] = (char)((bits >> (8*byte)) & 255);
    }
    return (long)bytes;
}
