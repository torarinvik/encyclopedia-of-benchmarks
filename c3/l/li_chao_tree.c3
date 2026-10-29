module li_chao_tree;

const usz MAX_OPERATIONS = 512;
const usz MAX_NODES = MAX_OPERATIONS * 24 + 1;
const long DOMAIN_LOW = -1000000;
const long DOMAIN_HIGH = 1000000;
const long COEFFICIENT_LIMIT = 1000;
const long CHECKSUM_OFFSET = 1000001001;

struct Node { long slope; long intercept; int left; int right; bool occupied; }

fn long evaluate(long slope, long intercept, long x) {
    return slope * x + intercept;
}

fn int allocate_node(Node* nodes, usz* used) {
    if (*used >= MAX_NODES) return -1;
    int id = (int)(*used);
    *used = *used + 1;
    nodes[id].slope = 0;
    nodes[id].intercept = 0;
    nodes[id].left = -1;
    nodes[id].right = -1;
    nodes[id].occupied = false;
    return id;
}

fn bool insert_at(Node* nodes, usz* used, int id, long low, long high, long slope, long intercept) {
    if (!nodes[id].occupied) {
        nodes[id].slope = slope;
        nodes[id].intercept = intercept;
        nodes[id].occupied = true;
        return true;
    }

    long middle = low + (high - low) / 2;
    if (evaluate(slope, intercept, middle) < evaluate(nodes[id].slope, nodes[id].intercept, middle)) {
        long old_slope = nodes[id].slope;
        long old_intercept = nodes[id].intercept;
        nodes[id].slope = slope;
        nodes[id].intercept = intercept;
        slope = old_slope;
        intercept = old_intercept;
    }
    if (low == high) return true;

    int child;
    long next_low;
    long next_high;
    if (evaluate(slope, intercept, low) < evaluate(nodes[id].slope, nodes[id].intercept, low)) {
        child = nodes[id].left;
        next_low = low;
        next_high = middle;
        if (child < 0) {
            child = allocate_node(nodes, used);
            if (child < 0) return false;
            nodes[id].left = child;
        }
    } else if (evaluate(slope, intercept, high) < evaluate(nodes[id].slope, nodes[id].intercept, high)) {
        child = nodes[id].right;
        next_low = middle + 1;
        next_high = high;
        if (child < 0) {
            child = allocate_node(nodes, used);
            if (child < 0) return false;
            nodes[id].right = child;
        }
    } else {
        return true;
    }
    return insert_at(nodes, used, child, next_low, next_high, slope, intercept);
}

fn long minimum_at(Node* nodes, int id, long low, long high, long x) {
    long best = evaluate(nodes[id].slope, nodes[id].intercept, x);
    if (low == high) return best;
    long middle = low + (high - low) / 2;
    bool go_left = x <= middle;
    int child = go_left ? nodes[id].left : nodes[id].right;
    if (child >= 0) {
        long nested = minimum_at(nodes, child, go_left ? low : middle + 1,
                                 go_left ? middle : high, x);
        if (nested < best) best = nested;
    }
    return best;
}

fn long li_chao_tree(long* values, usz length) @export("li_chao_tree") {
    if (values == null || length < 1 || length > 1 + 3 * MAX_OPERATIONS) return -1;
    if (values[0] < 0 || values[0] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)values[0];
    if (length != 1 + 3 * operation_count) return -1;

    Node[MAX_NODES] storage = {};
    Node* nodes = &storage[0];
    usz used = 0;
    int root = -1;
    usz inserted = 0;
    usz query_number = 0;
    long checksum = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = 1 + 3 * operation;
        long opcode = values[offset];
        long first = values[offset + 1];
        long second = values[offset + 2];
        if (opcode == 0) {
            if (first < -COEFFICIENT_LIMIT || first > COEFFICIENT_LIMIT || second < -COEFFICIENT_LIMIT || second > COEFFICIENT_LIMIT) return -1;
            if (root < 0) {
                root = allocate_node(nodes, &used);
                if (root < 0) return -1;
            }
            if (!insert_at(nodes, &used, root, DOMAIN_LOW, DOMAIN_HIGH, first, second)) return -1;
            inserted++;
        } else if (opcode == 1) {
            if (first < DOMAIN_LOW || first > DOMAIN_HIGH || second != 0 || inserted == 0) return -1;
            long answer = minimum_at(nodes, root, DOMAIN_LOW, DOMAIN_HIGH, first);
            query_number++;
            checksum += (long)query_number * (answer + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return checksum;
}
