module singlylinkedlist;

const usz MAX_PARSEABLE_INPUT_VALUES = 227;
const usz MAX_INITIAL_NODES = 32;
const usz MAX_OPERATIONS = 64;
const usz MAX_LIST_NODES = 96;
const usz MAX_OUTPUT_WORDS = 226;
const usz MAX_OUTPUT_BYTES = 1808;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;
const long INVALID_RESULT = -1;
const long OUTPUT_ERROR = -2;

struct ListNode { long value; int next; }

fn int allocate_node(ListNode* nodes, usz* allocated, long value) {
    int index = (int)*allocated;
    *allocated = *allocated + 1;
    nodes[index].value = value;
    nodes[index].next = -1;
    return index;
}

fn void append_result(long* results, usz* count, long success, long value) {
    results[*count] = success;
    *count = *count + 1;
    results[*count] = value;
    *count = *count + 1;
}

fn void reverse_list(ListNode* nodes, int* head, int* tail) {
    int previous = -1;
    int current = *head;
    *tail = *head;
    while (current != -1) {
        int next = nodes[current].next;
        nodes[current].next = previous;
        previous = current;
        current = next;
    }
    *head = previous;
}

fn void reverse_range(ListNode* nodes, int* head, int* tail,
                      usz list_count, usz left, usz right) {
    int before = -1;
    int segment_start = *head;
    for (usz index = 0; index < left; index++) {
        before = segment_start;
        segment_start = nodes[segment_start].next;
    }

    int previous = -1;
    int current = segment_start;
    for (usz index = left; index <= right; index++) {
        int next = nodes[current].next;
        nodes[current].next = previous;
        previous = current;
        current = next;
    }
    nodes[segment_start].next = current;
    if (before == -1) *head = previous;
    else nodes[before].next = previous;
    if (right + 1 == list_count) *tail = segment_start;
}

fn long remove_head(ListNode* nodes, int* head, int* tail, usz* list_count) {
    int removed = *head;
    long value = nodes[removed].value;
    *head = nodes[removed].next;
    *list_count = *list_count - 1;
    if (*list_count == 0) *tail = -1;
    return value;
}

fn long remove_tail(ListNode* nodes, int* head, int* tail, usz* list_count) {
    if (*list_count == 1) return remove_head(nodes, head, tail, list_count);
    int previous = *head;
    while (nodes[previous].next != *tail) previous = nodes[previous].next;
    int removed = *tail;
    long value = nodes[removed].value;
    nodes[previous].next = -1;
    *tail = previous;
    *list_count = *list_count - 1;
    return value;
}

fn void store_little_endian_i64(uint8* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[byte] = (uint8)(bits >> (8 * byte));
}

fn long singlylinkedlist(long* input, usz input_length, uint8* output,
                         usz output_capacity) @export("singlylinkedlist") {
    if (input == null || input_length < 2 ||
        input_length > MAX_PARSEABLE_INPUT_VALUES) return INVALID_RESULT;

    long initial_count_value = input[0];
    long operation_count_value = input[1];
    if (initial_count_value < 0 || initial_count_value > (long)MAX_INITIAL_NODES ||
        operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS)
        return INVALID_RESULT;

    usz initial_count = (usz)initial_count_value;
    usz operation_count = (usz)operation_count_value;
    usz cursor = 2;
    if (input_length < cursor + initial_count) return INVALID_RESULT;

    ListNode[MAX_LIST_NODES] nodes;
    usz allocated = 0;
    usz list_count = 0;
    int head = -1;
    int tail = -1;
    for (usz index = 0; index < initial_count; index++) {
        long value = input[cursor];
        cursor++;
        if (value < MIN_VALUE || value > MAX_VALUE) return INVALID_RESULT;
        int node = allocate_node(&nodes[0], &allocated, value);
        if (head == -1) head = node;
        else nodes[tail].next = node;
        tail = node;
        list_count++;
    }

    long[2 * MAX_OPERATIONS] operation_results;
    usz result_word_count = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        if (cursor >= input_length) return INVALID_RESULT;
        long opcode = input[cursor];
        cursor++;
        usz arity;
        if (opcode == 0 || opcode == 1 || opcode == 4) arity = 1;
        else if (opcode == 2 || opcode == 3 || opcode == 5) arity = 0;
        else if (opcode == 6) arity = 2;
        else return INVALID_RESULT;
        if (cursor + arity > input_length) return INVALID_RESULT;
        long first = arity >= 1 ? input[cursor] : 0;
        long second = arity == 2 ? input[cursor + 1] : 0;
        cursor += arity;

        if (opcode == 0 || opcode == 1) {
            if (first < MIN_VALUE || first > MAX_VALUE ||
                list_count >= MAX_LIST_NODES || allocated >= MAX_LIST_NODES)
                return INVALID_RESULT;
            int node = allocate_node(&nodes[0], &allocated, first);
            if (opcode == 0) {
                nodes[node].next = head;
                head = node;
                if (list_count == 0) tail = node;
            } else {
                if (list_count == 0) head = node;
                else nodes[tail].next = node;
                tail = node;
            }
            list_count++;
            append_result(operation_results, &result_word_count, 1, 0);
        } else if (opcode == 2) {
            if (list_count == 0)
                append_result(operation_results, &result_word_count, 0, 0);
            else
                append_result(operation_results, &result_word_count, 1,
                              remove_head(&nodes[0], &head, &tail, &list_count));
        } else if (opcode == 3) {
            if (list_count == 0)
                append_result(operation_results, &result_word_count, 0, 0);
            else
                append_result(operation_results, &result_word_count, 1,
                              remove_tail(&nodes[0], &head, &tail, &list_count));
        } else if (opcode == 4) {
            if (list_count == 0) {
                if (first != 1) return INVALID_RESULT;
                append_result(operation_results, &result_word_count, 0, 0);
            } else {
                if (first < 1 || first > (long)list_count + 1) return INVALID_RESULT;
                usz target = (usz)(first - 1);
                if (target >= list_count) target = list_count - 1;
                long value;
                if (target == 0) {
                    value = remove_head(&nodes[0], &head, &tail, &list_count);
                } else if (target + 1 == list_count) {
                    value = remove_tail(&nodes[0], &head, &tail, &list_count);
                } else {
                    int previous = head;
                    for (usz index = 1; index < target; index++)
                        previous = nodes[previous].next;
                    int removed = nodes[previous].next;
                    value = nodes[removed].value;
                    nodes[previous].next = nodes[removed].next;
                    list_count--;
                }
                append_result(operation_results, &result_word_count, 1, value);
            }
        } else if (opcode == 5) {
            if (list_count > 1) reverse_list(&nodes[0], &head, &tail);
            append_result(operation_results, &result_word_count, 1, 0);
        } else {
            if (first < 1 || second < first || second > (long)list_count)
                return INVALID_RESULT;
            reverse_range(&nodes[0], &head, &tail, list_count,
                          (usz)(first - 1), (usz)(second - 1));
            append_result(operation_results, &result_word_count, 1, 0);
        }
    }
    if (cursor != input_length) return INVALID_RESULT;

    long[MAX_OUTPUT_WORDS] output_words;
    usz output_word_count = 0;
    output_words[output_word_count] = (long)list_count;
    output_word_count++;
    int current = head;
    usz traversed = 0;
    while (current != -1 && traversed < list_count) {
        output_words[output_word_count] = nodes[current].value;
        output_word_count++;
        current = nodes[current].next;
        traversed++;
    }
    if (traversed != list_count || current != -1) return INVALID_RESULT;
    output_words[output_word_count] = (long)operation_count;
    output_word_count++;
    for (usz index = 0; index < result_word_count; index++) {
        output_words[output_word_count] = operation_results[index];
        output_word_count++;
    }

    usz output_bytes = output_word_count * 8;
    uint8[MAX_OUTPUT_BYTES] encoded;
    for (usz index = 0; index < output_word_count; index++)
        store_little_endian_i64(&encoded[index * 8], output_words[index]);

    if (output == null || output_capacity < output_bytes) return OUTPUT_ERROR;
    for (usz index = 0; index < output_bytes; index++) output[index] = encoded[index];
    return (long)output_bytes;
}
