#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_PARSEABLE_INPUT_VALUES 227
#define MAX_INITIAL_NODES 32
#define MAX_OPERATIONS 64
#define MAX_LIST_NODES 96
#define MAX_OUTPUT_WORDS 226
#define MIN_VALUE (-1000000)
#define MAX_VALUE 1000000
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)

typedef struct {
    int64_t value;
    int next;
} ListNode;

static int allocate_node(ListNode *nodes, size_t *allocated, int64_t value)
{
    const int index = (int)(*allocated);
    ++*allocated;
    nodes[index].value = value;
    nodes[index].next = -1;
    return index;
}

static void append_result(int64_t *results, size_t *count,
                          int64_t success, int64_t value)
{
    results[(*count)++] = success;
    results[(*count)++] = value;
}

static void reverse_list(ListNode *nodes, int *head, int *tail)
{
    int previous = -1;
    int current = *head;
    *tail = *head;
    while (current != -1) {
        const int next = nodes[current].next;
        nodes[current].next = previous;
        previous = current;
        current = next;
    }
    *head = previous;
}

static void reverse_range(ListNode *nodes, int *head, int *tail,
                          size_t list_count, size_t left, size_t right)
{
    int before = -1;
    int segment_start = *head;
    for (size_t index = 0; index < left; ++index) {
        before = segment_start;
        segment_start = nodes[segment_start].next;
    }

    int previous = -1;
    int current = segment_start;
    for (size_t index = left; index <= right; ++index) {
        const int next = nodes[current].next;
        nodes[current].next = previous;
        previous = current;
        current = next;
    }
    nodes[segment_start].next = current;
    if (before == -1) *head = previous;
    else nodes[before].next = previous;
    if (right + 1 == list_count) *tail = segment_start;
}

static int64_t remove_head(ListNode *nodes, int *head, int *tail,
                           size_t *list_count)
{
    const int removed = *head;
    const int64_t value = nodes[removed].value;
    *head = nodes[removed].next;
    --*list_count;
    if (*list_count == 0) *tail = -1;
    return value;
}

static int64_t remove_tail(ListNode *nodes, int *head, int *tail,
                           size_t *list_count)
{
    if (*list_count == 1) return remove_head(nodes, head, tail, list_count);
    int previous = *head;
    while (nodes[previous].next != *tail) previous = nodes[previous].next;
    const int removed = *tail;
    const int64_t value = nodes[removed].value;
    nodes[previous].next = -1;
    *tail = previous;
    --*list_count;
    return value;
}

static void store_little_endian_i64(uint8_t *output, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t singlylinkedlist(const int64_t *input, size_t input_length,
                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 ||
        input_length > MAX_PARSEABLE_INPUT_VALUES) return INVALID_RESULT;

    const int64_t initial_count_value = input[0];
    const int64_t operation_count_value = input[1];
    if (initial_count_value < 0 || initial_count_value > MAX_INITIAL_NODES ||
        operation_count_value < 0 || operation_count_value > MAX_OPERATIONS)
        return INVALID_RESULT;

    const size_t initial_count = (size_t)initial_count_value;
    const size_t operation_count = (size_t)operation_count_value;
    size_t cursor = 2;
    if (input_length < cursor + initial_count) return INVALID_RESULT;

    ListNode nodes[MAX_LIST_NODES] = {{0, -1}};
    size_t allocated = 0;
    size_t list_count = 0;
    int head = -1;
    int tail = -1;
    for (size_t index = 0; index < initial_count; ++index) {
        const int64_t value = input[cursor++];
        if (value < MIN_VALUE || value > MAX_VALUE) return INVALID_RESULT;
        const int node = allocate_node(nodes, &allocated, value);
        if (head == -1) head = node;
        else nodes[tail].next = node;
        tail = node;
        ++list_count;
    }

    int64_t operation_results[2 * MAX_OPERATIONS];
    size_t result_word_count = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= input_length) return INVALID_RESULT;
        const int64_t opcode = input[cursor++];
        size_t arity;
        switch (opcode) {
            case 0:
            case 1:
            case 4: arity = 1; break;
            case 2:
            case 3:
            case 5: arity = 0; break;
            case 6: arity = 2; break;
            default: return INVALID_RESULT;
        }
        if (cursor + arity > input_length) return INVALID_RESULT;
        const int64_t first = arity >= 1 ? input[cursor] : 0;
        const int64_t second = arity == 2 ? input[cursor + 1] : 0;
        cursor += arity;

        if (opcode == 0 || opcode == 1) {
            if (first < MIN_VALUE || first > MAX_VALUE ||
                list_count >= MAX_LIST_NODES || allocated >= MAX_LIST_NODES)
                return INVALID_RESULT;
            const int node = allocate_node(nodes, &allocated, first);
            if (opcode == 0) {
                nodes[node].next = head;
                head = node;
                if (list_count == 0) tail = node;
            } else {
                if (list_count == 0) head = node;
                else nodes[tail].next = node;
                tail = node;
            }
            ++list_count;
            append_result(operation_results, &result_word_count, 1, 0);
        } else if (opcode == 2) {
            if (list_count == 0)
                append_result(operation_results, &result_word_count, 0, 0);
            else
                append_result(operation_results, &result_word_count, 1,
                              remove_head(nodes, &head, &tail, &list_count));
        } else if (opcode == 3) {
            if (list_count == 0)
                append_result(operation_results, &result_word_count, 0, 0);
            else
                append_result(operation_results, &result_word_count, 1,
                              remove_tail(nodes, &head, &tail, &list_count));
        } else if (opcode == 4) {
            if (list_count == 0) {
                if (first != 1) return INVALID_RESULT;
                append_result(operation_results, &result_word_count, 0, 0);
            } else {
                if (first < 1 || first > (int64_t)list_count + 1)
                    return INVALID_RESULT;
                size_t target = (size_t)(first - 1);
                if (target >= list_count) target = list_count - 1;
                int64_t value;
                if (target == 0) {
                    value = remove_head(nodes, &head, &tail, &list_count);
                } else if (target + 1 == list_count) {
                    value = remove_tail(nodes, &head, &tail, &list_count);
                } else {
                    int previous = head;
                    for (size_t index = 1; index < target; ++index)
                        previous = nodes[previous].next;
                    const int removed = nodes[previous].next;
                    value = nodes[removed].value;
                    nodes[previous].next = nodes[removed].next;
                    --list_count;
                }
                append_result(operation_results, &result_word_count, 1, value);
            }
        } else if (opcode == 5) {
            if (list_count > 1) reverse_list(nodes, &head, &tail);
            append_result(operation_results, &result_word_count, 1, 0);
        } else {
            if (first < 1 || second < first || second > (int64_t)list_count)
                return INVALID_RESULT;
            reverse_range(nodes, &head, &tail, list_count,
                          (size_t)(first - 1), (size_t)(second - 1));
            append_result(operation_results, &result_word_count, 1, 0);
        }
    }
    if (cursor != input_length) return INVALID_RESULT;

    int64_t output_words[MAX_OUTPUT_WORDS];
    size_t output_word_count = 0;
    output_words[output_word_count++] = (int64_t)list_count;
    int current = head;
    size_t traversed = 0;
    while (current != -1 && traversed < list_count) {
        output_words[output_word_count++] = nodes[current].value;
        current = nodes[current].next;
        ++traversed;
    }
    if (traversed != list_count || current != -1) return INVALID_RESULT;
    output_words[output_word_count++] = (int64_t)operation_count;
    for (size_t index = 0; index < result_word_count; ++index)
        output_words[output_word_count++] = operation_results[index];

    const size_t output_bytes = output_word_count * 8;
    uint8_t encoded[8 * MAX_OUTPUT_WORDS];
    for (size_t index = 0; index < output_word_count; ++index)
        store_little_endian_i64(encoded + index * 8, output_words[index]);

    if (output == NULL || output_capacity < output_bytes) return OUTPUT_ERROR;
    memcpy(output, encoded, output_bytes);
    return (int64_t)output_bytes;
}
