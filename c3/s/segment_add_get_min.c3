module segment_add_get_min;

const usz MAX_INITIAL_SEGMENTS = 16;
const usz MAX_OPERATIONS = 32;
const long DOMAIN_LOW = -32;
const long DOMAIN_HIGH = 31;
const long DOMAIN_RIGHT = 32;
const long COEFFICIENT_LIMIT = 1000;
const long INFINITY_VALUE = 1000000000000;
const long CHECKSUM_OFFSET = 33001;
const usz TREE_CAPACITY = 4 * 64 + 8;
const usz MAX_INPUT_LENGTH = 2 + 4 * MAX_INITIAL_SEGMENTS + 5 * MAX_OPERATIONS;

struct Node { long slope; long intercept; bool occupied; }

fn long evaluate(long slope, long intercept, long x) {
    return slope * x + intercept;
}

fn void add_line(Node* tree, usz node, long low, long high, long slope, long intercept) {
    if (!tree[node].occupied) {
        tree[node].slope = slope;
        tree[node].intercept = intercept;
        tree[node].occupied = true;
        return;
    }
    long middle = low + (high - low) / 2;
    if (evaluate(slope, intercept, middle) < evaluate(tree[node].slope, tree[node].intercept, middle)) {
        long old_slope = tree[node].slope;
        long old_intercept = tree[node].intercept;
        tree[node].slope = slope;
        tree[node].intercept = intercept;
        slope = old_slope;
        intercept = old_intercept;
    }
    if (low == high) return;
    if (evaluate(slope, intercept, low) < evaluate(tree[node].slope, tree[node].intercept, low)) {
        add_line(tree, 2 * node, low, middle, slope, intercept);
    } else if (evaluate(slope, intercept, high) < evaluate(tree[node].slope, tree[node].intercept, high)) {
        add_line(tree, 2 * node + 1, middle + 1, high, slope, intercept);
    }
}

fn void add_segment(Node* tree, usz node, long low, long high,
                    long query_low, long query_high, long slope, long intercept) {
    if (query_high <= low || high < query_low) return;
    if (query_low <= low && high < query_high) {
        add_line(tree, node, low, high, slope, intercept);
        return;
    }
    long middle = low + (high - low) / 2;
    add_segment(tree, 2 * node, low, middle, query_low, query_high, slope, intercept);
    add_segment(tree, 2 * node + 1, middle + 1, high, query_low, query_high, slope, intercept);
}

fn long minimum_at(Node* tree, usz node, long low, long high, long x) {
    long best = INFINITY_VALUE;
    if (tree[node].occupied) best = evaluate(tree[node].slope, tree[node].intercept, x);
    if (low == high) return best;
    long middle = low + (high - low) / 2;
    bool go_left = x <= middle;
    long nested = minimum_at(tree, go_left ? 2 * node : 2 * node + 1,
                             go_left ? low : middle + 1, go_left ? middle : high, x);
    return nested < best ? nested : best;
}

fn bool valid_segment(long left, long right, long slope, long intercept) {
    return left >= DOMAIN_LOW && left < right && right <= DOMAIN_RIGHT
        && slope >= -COEFFICIENT_LIMIT && slope <= COEFFICIENT_LIMIT
        && intercept >= -COEFFICIENT_LIMIT && intercept <= COEFFICIENT_LIMIT;
}

fn long segment_add_get_min(long* values, usz length) @export("segment_add_get_min") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long initial_value = values[0];
    long operation_value = values[1];
    if (initial_value < 0 || initial_value > (long)MAX_INITIAL_SEGMENTS
        || operation_value < 0 || operation_value > (long)MAX_OPERATIONS) return -1;
    usz initial_count = (usz)initial_value;
    usz operation_count = (usz)operation_value;

    Node[TREE_CAPACITY] storage = zeroed;
    Node* tree = &storage[0];
    usz position = 2;
    for (usz index = 0; index < initial_count; index++) {
        if (length - position < 4) return -1;
        long left = values[position];
        long right = values[position + 1];
        long slope = values[position + 2];
        long intercept = values[position + 3];
        if (!valid_segment(left, right, slope, intercept)) return -1;
        add_segment(tree, 1, DOMAIN_LOW, DOMAIN_HIGH, left, right, slope, intercept);
        position += 4;
    }

    long checksum = 0;
    long query_number = 0;
    for (usz index = 0; index < operation_count; index++) {
        if (position >= length) return -1;
        long opcode = values[position];
        position++;
        if (opcode == 0) {
            if (length - position < 4) return -1;
            long left = values[position];
            long right = values[position + 1];
            long slope = values[position + 2];
            long intercept = values[position + 3];
            if (!valid_segment(left, right, slope, intercept)) return -1;
            add_segment(tree, 1, DOMAIN_LOW, DOMAIN_HIGH, left, right, slope, intercept);
            position += 4;
        } else if (opcode == 1) {
            if (position >= length) return -1;
            long x = values[position];
            position++;
            if (x < DOMAIN_LOW || x > DOMAIN_HIGH) return -1;
            long answer = minimum_at(tree, 1, DOMAIN_LOW, DOMAIN_HIGH, x);
            query_number++;
            checksum += query_number * (answer + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return position == length ? checksum : -1;
}
