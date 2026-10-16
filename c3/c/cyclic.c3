module cyclic;
const usz MAX_NODES = 64;
const usz MAX_OPERATIONS = 64;
const usz MAX_RECORD_FIELDS = 5000;

fn void rotate_list(long* next, long* previous, long* head, long size, long places) {
    if (size == 0) return;
    long steps = places % size;
    if (steps < 0) steps += size;
    if (steps > size / 2) { steps = size - steps; for (long i = 0; i < steps; i++) *head = previous[*head]; }
    else { for (long i = 0; i < steps; i++) *head = next[*head]; }
}

fn bool delete_head(long* values, long* next, long* previous, long* head, long* size) {
    if (*size == 0) return false;
    long current = *head;
    if (*size == 1) *head = -1;
    else {
        long successor = next[current], predecessor = previous[current];
        next[predecessor] = successor; previous[successor] = predecessor; *head = successor;
    }
    values[current] = 0; *size = *size - 1;
    return true;
}

fn void add_record(long* records, usz* field_count, long value) { records[*field_count] = value; *field_count = *field_count + 1; }

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long cyclic(long* input, usz length, char* output, usz capacity) @export("cyclic") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > 64) return -1;
    usz operation_count = (usz)input[0];
    if (length != 1 + 2 * operation_count) return -1;
    long[64] values = {}, next = {}, previous = {};
    long head = -1, size = 0, allocated = 0;
    long[5000] records = {};
    usz record_fields = 0, query_count = 0;
    for (usz index = 0; index < operation_count; index++) {
        long operation = input[1 + 2 * index], argument = input[2 + 2 * index];
        if (operation < 0 || operation > 5) return -1;
        if (operation == 0) {
            if (argument < -2147483648 || argument > 2147483647 || allocated >= 64) return -1;
            long node = allocated++; values[node] = argument;
            if (size == 0) { head = node; next[node] = head; previous[node] = head; }
            else { long tail = previous[head]; previous[node] = tail; next[node] = head; next[tail] = node; previous[head] = node; }
            size++;
        } else if (operation == 1) {
            if (argument < -1000000 || argument > 1000000) return -1;
            rotate_list(&next[0], &previous[0], &head, size, argument);
        } else if (operation == 2) {
            if (argument != 0) return -1;
            long deleted = 0; if (delete_head(&values[0], &next[0], &previous[0], &head, &size)) deleted = 1;
            add_record(&records[0], &record_fields, (long)index); add_record(&records[0], &record_fields, operation);
            add_record(&records[0], &record_fields, 1); add_record(&records[0], &record_fields, deleted); query_count++;
        } else if (operation == 3) {
            if (argument != 0) return -1;
            add_record(&records[0], &record_fields, (long)index); add_record(&records[0], &record_fields, operation); add_record(&records[0], &record_fields, size);
            long cursor = head;
            for (long i = 0; i < size; i++) { add_record(&records[0], &record_fields, values[cursor]); cursor = next[cursor]; }
            query_count++;
        } else if (operation == 4) {
            if (argument < -1000000 || argument > 1000000 || size == 0) return -1;
            while (size > 1) { rotate_list(&next[0], &previous[0], &head, size, argument); (void)delete_head(&values[0], &next[0], &previous[0], &head, &size); rotate_list(&next[0], &previous[0], &head, size, -1); }
            long winner = values[head];
            while (delete_head(&values[0], &next[0], &previous[0], &head, &size)) {}
            add_record(&records[0], &record_fields, (long)index); add_record(&records[0], &record_fields, operation);
            add_record(&records[0], &record_fields, 1); add_record(&records[0], &record_fields, winner); query_count++;
        } else {
            if (argument != 0) return -1;
            while (delete_head(&values[0], &next[0], &previous[0], &head, &size)) {}
        }
    }
    usz required = (1 + record_fields + 1 + (usz)size) * 8;
    if (output == null || capacity < required) return -2;
    usz field = 0; put_i64(output, field++ * 8, (long)query_count);
    for (usz i = 0; i < record_fields; i++) put_i64(output, field++ * 8, records[i]);
    put_i64(output, field++ * 8, size);
    long cursor = head;
    for (long i = 0; i < size; i++) { put_i64(output, field++ * 8, values[cursor]); cursor = next[cursor]; }
    return (long)required;
}
