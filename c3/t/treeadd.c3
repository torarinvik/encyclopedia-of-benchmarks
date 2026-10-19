module treeadd;

const int MAX_LEVEL = 12;
const int MAX_NODES = (1 << MAX_LEVEL) - 1;
const int ADDITION_PASSES = 100;

struct Node { int value; int left; int right; }

fn int allocate_tree(Node* nodes, int* used, int level, int lo, int proc_count) {
    if (level == 0 || *used >= MAX_NODES) return -1;
    int index = *used;
    *used = *used + 1;
    nodes[index].value = 1;
    int left = allocate_tree(nodes, used, level - 1, lo + proc_count / 2, proc_count / 2);
    int right = allocate_tree(nodes, used, level - 1, lo, proc_count / 2);
    nodes[index].left = left;
    nodes[index].right = right;
    return index;
}

fn long tree_add(Node* nodes, int index) {
    if (index < 0) return 0;
    return (long)nodes[index].value + tree_add(nodes, nodes[index].left) +
           tree_add(nodes, nodes[index].right);
}

fn long treeadd(long level) @export("treeadd") {
    if (level < 0 || level > MAX_LEVEL) return -1;
    Node[MAX_NODES] nodes;
    int used = 0;
    int root = allocate_tree(&nodes[0], &used, (int)level, 0, 4);
    long result = 0;
    for (int pass = 0; pass < ADDITION_PASSES; pass++) {
        result = tree_add(&nodes[0], root);
    }
    return result;
}
