module search_singly_linked_list_recursion;

const usz MAX_NODES = 64;
const long I32_MIN = -2147483648L;
const long I32_MAX = 2147483647L;
struct Node { int value; int next; }

fn bool search_recursion(Node* nodes, int current, int count, int key) {
    if (current >= count) return false;
    return nodes[current].value == key || search_recursion(nodes, nodes[current].next, count, key);
}

fn long search_singly_linked_list_recursion(long* input, usz length) @export("search_singly_linked_list_recursion") {
    if (input == null || length < 2 || length > MAX_NODES + 2) return -1;
    long count_value = input[0];
    long key = input[1];
    if (count_value < 0 || count_value > (long)MAX_NODES || length != (usz)count_value + 2 ||
        key < I32_MIN || key > I32_MAX) return -1;
    usz count = (usz)count_value;
    Node[MAX_NODES] nodes;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 2];
        if (value < I32_MIN || value > I32_MAX) return -1;
        nodes[index].value = (int)value;
        nodes[index].next = (int)index + 1;
    }
    return search_recursion(&nodes[0], 0, (int)count, (int)key) ? 1 : 0;
}
