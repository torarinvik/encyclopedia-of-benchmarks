module centroid_decomposition;

const int MAX_NODES = 64;
const int MAX_DIRECTED_EDGES = 2 * (MAX_NODES - 1);
const int INVALID_PARENT = -2;

fn int cd_find_set(int* parent, int node) {
    while (parent[node] != node) node = parent[node];
    return node;
}

fn long centroid_decomposition(long* input, usz length, char* output,
                               usz output_capacity) @export("centroid_decomposition") {
    if (input == null || length < 1 || length > 2 * MAX_NODES - 1) return -1;
    if (input[0] < 1 || input[0] > MAX_NODES) return -1;
    int node_count = (int)input[0];
    if (length != (usz)(2 * node_count - 1)) return -1;

    int[MAX_NODES] set_parent;
    int[MAX_NODES] head;
    int[MAX_DIRECTED_EDGES] edge_to;
    int[MAX_DIRECTED_EDGES] edge_next;
    int edge_count = 0;
    for (usz node = 0; node < (usz)node_count; node++) {
        set_parent[node] = (int)node;
        head[node] = -1;
    }
    for (usz position = 1; position < length; position += 2) {
        long left_value = input[position];
        long right_value = input[position + 1];
        if (left_value < 0 || left_value >= node_count || right_value < 0 || right_value >= node_count || left_value == right_value) return -1;
        int left = (int)left_value;
        int right = (int)right_value;
        int left_root = cd_find_set(&set_parent[0], left);
        int right_root = cd_find_set(&set_parent[0], right);
        if (left_root == right_root) return -1;
        set_parent[right_root] = left_root;

        edge_to[edge_count] = right;
        edge_next[edge_count] = head[left];
        head[left] = edge_count;
        edge_count++;
        edge_to[edge_count] = left;
        edge_next[edge_count] = head[right];
        head[right] = edge_count;
        edge_count++;
    }
    usz required_bytes = (usz)node_count * 4;
    if (output_capacity < required_bytes || output == null) return -2;

    bool[MAX_NODES] removed;
    int[MAX_NODES] traversal_parent;
    int[MAX_NODES] subtree_size;
    int[MAX_NODES] order;
    int[MAX_NODES] stack;
    int[MAX_NODES] task_node;
    int[MAX_NODES] task_parent;
    int[MAX_NODES] decomposition_parent;
    for (usz node = 0; node < (usz)node_count; node++) {
        removed[node] = false;
        decomposition_parent[node] = INVALID_PARENT;
    }
    int task_count = 1;
    task_node[0] = 0;
    task_parent[0] = -1;

    while (task_count > 0) {
        task_count--;
        int start = task_node[task_count];
        int centroid_parent = task_parent[task_count];
        for (usz node = 0; node < (usz)node_count; node++) traversal_parent[node] = INVALID_PARENT;
        int stack_count = 1;
        int order_count = 0;
        stack[0] = start;
        traversal_parent[start] = -1;
        while (stack_count > 0) {
            stack_count--;
            int node = stack[stack_count];
            order[order_count] = node;
            order_count++;
            subtree_size[node] = 1;
            int edge = head[node];
            while (edge >= 0) {
                int neighbor = edge_to[edge];
                if (neighbor != traversal_parent[node] && !removed[neighbor]
                    && traversal_parent[neighbor] == INVALID_PARENT) {
                    traversal_parent[neighbor] = node;
                    stack[stack_count] = neighbor;
                    stack_count++;
                }
                edge = edge_next[edge];
            }
        }
        int index = order_count;
        while (index > 0) {
            index--;
            int node = order[index];
            int parent = traversal_parent[node];
            if (parent >= 0) subtree_size[parent] += subtree_size[node];
        }

        int centroid = -1;
        int smallest_largest_branch = node_count + 1;
        for (int order_index = 0; order_index < order_count; order_index++) {
            int node = order[order_index];
            int largest_branch = order_count - subtree_size[node];
            int edge = head[node];
            while (edge >= 0) {
                int neighbor = edge_to[edge];
                if (traversal_parent[neighbor] == node
                    && subtree_size[neighbor] > largest_branch) {
                    largest_branch = subtree_size[neighbor];
                }
                edge = edge_next[edge];
            }
            if (largest_branch < smallest_largest_branch
                || (largest_branch == smallest_largest_branch && node < centroid)) {
                centroid = node;
                smallest_largest_branch = largest_branch;
            }
        }
        decomposition_parent[centroid] = centroid_parent;
        removed[centroid] = true;
        int edge = head[centroid];
        while (edge >= 0) {
            int neighbor = edge_to[edge];
            if (!removed[neighbor]) {
                task_node[task_count] = neighbor;
                task_parent[task_count] = centroid;
                task_count++;
            }
            edge = edge_next[edge];
        }
    }

    for (int node = 0; node < node_count; node++) {
        long parent = decomposition_parent[node];
        output[4 * node] = (char)(parent & 255);
        output[4 * node + 1] = (char)((parent >> 8) & 255);
        output[4 * node + 2] = (char)((parent >> 16) & 255);
        output[4 * node + 3] = (char)((parent >> 24) & 255);
    }
    return node_count;
}
