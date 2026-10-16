module threaded_binary_tree;

const int MAX_NODES = 128;
struct Node { int key; int left; int right; bool left_is_thread; bool right_is_thread; }

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long threaded_binary_tree(long* input, usz length, char* output, usz output_capacity)
    @export("threaded_binary_tree")
{
    if (input == null || length < 1 || input[0] < 0 || input[0] > MAX_NODES) return -1;
    usz count = (usz)input[0];
    if (length != 1 + count) return -1;
    for (usz i = 0; i < count; i++)
        if (input[i + 1] < -2147483648 || input[i + 1] > 2147483647) return -1;

    usz required = count * 4;
    if (required > 0 && (output == null || output_capacity < required)) return -2;

    Node[MAX_NODES] nodes;
    int root = -1;
    for (usz inserted = 0; inserted < count; inserted++) {
        int node = (int)inserted;
        int key = (int)input[inserted + 1];
        nodes[node].key = key;
        nodes[node].left = -1;
        nodes[node].right = -1;
        nodes[node].left_is_thread = false;
        nodes[node].right_is_thread = false;
        if (root == -1) {
            root = node;
            continue;
        }

        int current = root;
        int parent = -1;
        while (true) {
            parent = current;
            if (key < nodes[current].key) {
                if (!nodes[current].left_is_thread && nodes[current].left != -1) current = nodes[current].left;
                else break;
            } else {
                if (!nodes[current].right_is_thread && nodes[current].right != -1) current = nodes[current].right;
                else break;
            }
        }

        if (key < nodes[parent].key) {
            nodes[node].left = nodes[parent].left;
            nodes[node].left_is_thread = nodes[parent].left_is_thread;
            nodes[node].right = parent;
            nodes[node].right_is_thread = true;
            nodes[parent].left = node;
            nodes[parent].left_is_thread = false;
        } else {
            nodes[node].right = nodes[parent].right;
            nodes[node].right_is_thread = nodes[parent].right_is_thread;
            nodes[node].left = parent;
            nodes[node].left_is_thread = true;
            nodes[parent].right = node;
            nodes[parent].right_is_thread = false;
        }
    }

    int current = root;
    while (current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1) current = nodes[current].left;
    usz written = 0;
    while (current != -1) {
        put_i32_le(output, written, nodes[current].key);
        written += 4;
        if (nodes[current].right_is_thread) current = nodes[current].right;
        else {
            current = nodes[current].right;
            while (current != -1 && !nodes[current].left_is_thread && nodes[current].left != -1) current = nodes[current].left;
        }
    }
    return (long)written;
}
