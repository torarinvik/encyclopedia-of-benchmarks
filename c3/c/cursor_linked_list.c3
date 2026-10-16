module cursor_linked_list;
const usz CURSOR_SPACE_SIZE = 100;
const usz MAX_OPERATIONS = 64;

fn bool find_value(long* elements, bool* occupied, long* next, long head, long value, long* previous, long* found) {
    *previous = -1; *found = head;
    while (*found != -1 && (!occupied[*found] || elements[*found] != value)) { *previous = *found; *found = next[*found]; }
    return *found != -1;
}

fn void free_node(long* elements, bool* occupied, long* next, long index) {
    long old_free_head = next[0]; occupied[index] = false; elements[index] = 0;
    next[index] = old_free_head; next[0] = index;
}

fn bool remove_value(long* elements, bool* occupied, long* next, long* head, long* count, long value) {
    if (*head == -1) return false;
    long previous, current;
    if (!find_value(elements, occupied, next, *head, value, &previous, &current)) return false;
    long successor = next[current];
    if (previous == -1) { free_node(elements, occupied, next, current); *head = successor; }
    else { next[previous] = successor; free_node(elements, occupied, next, current); }
    *count = *count - 1;
    return true;
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long cursor_linked_list(long* input, usz length, char* output, usz capacity) @export("cursor_linked_list") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > 64) return -1;
    usz operation_count = (usz)input[0];
    if (length != 1 + 2 * operation_count) return -1;
    long[100] elements = {}; long[100] next = {}; bool[100] occupied = {};
    for (usz i = 0; i < 100; i++) next[i] = (long)i + 1;
    next[99] = 0;
    long head = -1, count = 0;
    long[64] query_found = {}; long[64] query_values = {}; usz query_count = 0;
    for (usz index = 0; index < operation_count; index++) {
        long operation = input[1 + 2 * index], argument = input[2 + 2 * index];
        if (operation < 0 || operation > 4 || argument < -2147483648 || argument > 2147483647) return -1;
        if (operation == 0) {
            long available = next[0]; if (available == 0) return -1;
            next[0] = next[available]; next[available] = -1; elements[available] = argument; occupied[available] = true;
            if (head == -1) head = available;
            else { long tail = head; while (next[tail] != -1) tail = next[tail]; next[tail] = available; }
            next[available] = -1; count++;
        } else if (operation == 1) {
            if (!remove_value(&elements[0], &occupied[0], &next[0], &head, &count, argument)) return -1;
        } else if (operation == 2) {
            if (argument < 0 || argument >= count) return -1;
            long cursor = head; for (long i = 0; i < argument; i++) cursor = next[cursor];
            long value = elements[cursor];
            if (!remove_value(&elements[0], &occupied[0], &next[0], &head, &count, value)) return -1;
        } else if (operation == 3) {
            if (argument >= 0 && argument < count) {
                long cursor = head; for (long i = 0; i < argument; i++) cursor = next[cursor];
                query_found[query_count] = 1; query_values[query_count] = elements[cursor];
            }
            query_count++;
        } else {
            long previous, found;
            if (find_value(&elements[0], &occupied[0], &next[0], head, argument, &previous, &found)) {
                long logical_index = 0, cursor = head;
                while (cursor != found) { cursor = next[cursor]; logical_index++; }
                query_found[query_count] = 1; query_values[query_count] = logical_index;
            }
            query_count++;
        }
    }
    usz required = (1 + 2 * query_count + 2 + 3 * 100) * 8;
    if (output == null || capacity < required) return -2;
    usz field = 0; put_i64(output, field++ * 8, (long)query_count);
    for (usz i = 0; i < query_count; i++) { put_i64(output, field++ * 8, query_found[i]); put_i64(output, field++ * 8, query_values[i]); }
    put_i64(output, field++ * 8, head); put_i64(output, field++ * 8, count);
    for (usz i = 0; i < 100; i++) { put_i64(output, field++ * 8, occupied[i] ? 1 : 0); put_i64(output, field++ * 8, elements[i]); put_i64(output, field++ * 8, next[i]); }
    return (long)required;
}
