/* Recursively count a finite singly linked chain represented in node order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MIN_PAYLOAD (-2147483647LL - 1LL)
#define MAX_PAYLOAD 2147483647LL

static int64_t count_recursive(const int64_t *nodes, size_t remaining)
{
    if (remaining == 0) return 0;
    if (nodes[0] < MIN_PAYLOAD || nodes[0] > MAX_PAYLOAD) return -1;
    const int64_t tail_count = count_recursive(nodes + 1, remaining - 1);
    return tail_count < 0 ? -1 : 1 + tail_count;
}

int64_t count_singly_linked_list_recursion(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_NODES) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1) return -1;
    return count_recursive(input + 1, count);
}
