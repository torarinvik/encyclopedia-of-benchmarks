module stanford_treesort;

const long MIN_RUNS = 1;
const long MAX_RUNS = 100;
const usz ELEMENT_COUNT = 5000;
const usz MAX_OUTPUT_BYTES = 700;
const int NO_CHILD = -1;

struct TreeNode {
    int value;
    int left;
    int right;
}

fn int next_random(long* seed) {
    *seed = (*seed * 1309 + 13849) & 65535;
    return (int)*seed;
}

fn bool validate_tree(TreeNode* nodes, int root) {
    if (nodes[root].left != NO_CHILD) {
        int child = nodes[root].left;
        if (nodes[child].value <= nodes[root].value) return false;
        if (!validate_tree(nodes, child)) return false;
    }
    if (nodes[root].right != NO_CHILD) {
        int child = nodes[root].right;
        if (nodes[child].value >= nodes[root].value) return false;
        if (!validate_tree(nodes, child)) return false;
    }
    return true;
}

fn bool build_and_check_pass(int selected_run, int* selected_value) {
    int[ELEMENT_COUNT] values;
    TreeNode[ELEMENT_COUNT] nodes;
    long seed = 74755;
    for (usz i = 0; i < ELEMENT_COUNT; ++i) {
        int temp = next_random(&seed);
        values[i] = temp - (temp / 100000) * 100000 - 50000;
    }

    nodes[0].value = values[0];
    nodes[0].left = NO_CHILD;
    nodes[0].right = NO_CHILD;
    int used = 1;
    for (usz i = 1; i < ELEMENT_COUNT; ++i) {
        int current = 0;
        while (true) {
            int* child;
            if (values[i] > nodes[current].value) child = &nodes[current].left;
            else if (values[i] < nodes[current].value) child = &nodes[current].right;
            else break;
            if (*child == NO_CHILD) {
                *child = used;
                nodes[used].value = values[i];
                nodes[used].left = NO_CHILD;
                nodes[used].right = NO_CHILD;
                ++used;
                break;
            }
            current = *child;
        }
    }
    *selected_value = values[selected_run + 1];
    return validate_tree(&nodes[0], 0);
}

fn void append_text(char* buffer, usz* used, const char* text) {
    while (*text != '\0') {
        buffer[*used] = *text;
        *used = *used + 1;
        text++;
    }
}

fn void append_integer(char* buffer, usz* used, int value) {
    int remaining = value;
    if (remaining < 0) {
        buffer[*used] = '-';
        *used = *used + 1;
        remaining = -remaining;
    }
    char[12] reverse;
    usz count = 0;
    do {
        reverse[count++] = (char)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    while (count > 0) {
        count--;
        buffer[*used] = reverse[count];
        *used = *used + 1;
    }
}

fn long stanford_treesort(long runs, char* output, usz output_capacity)
    @export("stanford_treesort") {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == null) return -2;

    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    for (int run = 0; run < (int)runs; ++run) {
        int selected_value = 0;
        bool valid = build_and_check_pass(run, &selected_value);
        append_integer(&staged[0], &used, selected_value);
        append_text(&staged[0], &used, "\n");
        if (!valid) append_text(&staged[0], &used, " Error in Tree.\n");
    }
    if (output_capacity < used) return -2;
    for (usz i = 0; i < used; ++i) output[i] = staged[i];
    return (long)used;
}
