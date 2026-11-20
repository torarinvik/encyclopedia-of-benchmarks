module bdd_symbolic_reachability;

const usz MAX_INPUT = 133;
const usz MAX_NODES = 17000;
const usz UNIQUE_CAP = 32768;

struct Manager {
    uchar[MAX_NODES] variable;
    ushort[MAX_NODES] low;
    ushort[MAX_NODES] high;
    ushort[UNIQUE_CAP] unique;
    ushort[MAX_NODES] exists_result;
    ushort[MAX_NODES] rename_result;
    ushort next_id;
    uchar variable_count;
    bool failed;
}

fn usz unique_hash(usz variable, usz low, usz high) {
    return (variable * 4099 + low * 131 + high) & (UNIQUE_CAP - 1);
}

fn ushort make_node(Manager* manager, uchar variable, ushort low, ushort high) {
    if (low == high) return low;
    usz slot = unique_hash((usz)variable, (usz)low, (usz)high);
    for (usz probes = 0; probes < UNIQUE_CAP; probes++) {
        ushort encoded = manager.unique[slot];
        if (encoded == 0) {
            if ((usz)manager.next_id >= MAX_NODES) {
                manager.failed = true;
                return 0;
            }
            ushort id = manager.next_id++;
            manager.variable[id] = variable;
            manager.low[id] = low;
            manager.high[id] = high;
            manager.unique[slot] = (ushort)(id + 1);
            return id;
        }
        ushort id = encoded - 1;
        if (manager.variable[id] == variable && manager.low[id] == low && manager.high[id] == high)
            return id;
        slot = (slot + 1) & (UNIQUE_CAP - 1);
    }
    manager.failed = true;
    return 0;
}

fn void reset_round(Manager* manager, ushort relation_end) {
    for (usz i = 0; i < UNIQUE_CAP; i++) manager.unique[i] = 0;
    for (usz i = 0; i < MAX_NODES; i++) {
        manager.exists_result[i] = 0;
        manager.rename_result[i] = 0;
    }
    manager.next_id = relation_end;
    for (usz id = 2; id < (usz)relation_end; id++) {
        usz slot = unique_hash((usz)manager.variable[id], (usz)manager.low[id],
                               (usz)manager.high[id]);
        while (manager.unique[slot] != 0)
            slot = (slot + 1) & (UNIQUE_CAP - 1);
        manager.unique[slot] = (ushort)(id + 1);
    }
}

fn uchar top_variable(Manager* manager, ushort node) {
    return node < 2 ? manager.variable_count : manager.variable[node];
}

fn ushort apply_recursive(Manager* manager, ushort left, ushort right, bool is_or) {
    if (manager.failed) return 0;
    if (is_or) {
        if (left == 1 || right == 1) return 1;
        if (left == 0) return right;
        if (right == 0 || left == right) return left;
    } else {
        if (left == 0 || right == 0) return 0;
        if (left == 1) return right;
        if (right == 1 || left == right) return left;
    }
    uchar variable = top_variable(manager, left);
    uchar right_variable = top_variable(manager, right);
    if (right_variable < variable) variable = right_variable;
    ushort left_low = left, left_high = left, right_low = right, right_high = right;
    if (left >= 2 && manager.variable[left] == variable) {
        left_low = manager.low[left]; left_high = manager.high[left];
    }
    if (right >= 2 && manager.variable[right] == variable) {
        right_low = manager.low[right]; right_high = manager.high[right];
    }
    ushort result_low = apply_recursive(manager, left_low, right_low, is_or);
    ushort result_high = apply_recursive(manager, left_high, right_high, is_or);
    ushort result = make_node(manager, variable, result_low, result_high);
    if (manager.failed) return 0;
    return result;
}

fn ushort apply_binary(Manager* manager, ushort left, ushort right, bool is_or) {
    return apply_recursive(manager, left, right, is_or);
}

fn ushort truth_recursive(Manager* manager, long* bits, uchar variable,
                          usz prefix, uchar variable_count) {
    if (manager.failed) return 0;
    if (variable == variable_count) return (ushort)bits[prefix];
    ushort low = truth_recursive(manager, bits, (uchar)(variable + 1), prefix * 2, variable_count);
    ushort high = truth_recursive(manager, bits, (uchar)(variable + 1), prefix * 2 + 1, variable_count);
    return make_node(manager, variable, low, high);
}

fn ushort exists_recursive(Manager* manager, ushort node, uchar quantified_variables) {
    if (manager.failed || node < 2) return node;
    ushort cached = manager.exists_result[node];
    if (cached != 0) return cached - 1;
    uchar variable = manager.variable[node];
    ushort low = exists_recursive(manager, manager.low[node], quantified_variables);
    ushort high = exists_recursive(manager, manager.high[node], quantified_variables);
    ushort result = variable < quantified_variables
        ? apply_binary(manager, low, high, true)
        : make_node(manager, variable, low, high);
    if (!manager.failed) manager.exists_result[node] = (ushort)(result + 1);
    return result;
}

fn ushort rename_recursive(Manager* manager, ushort node, uchar first_variable) {
    if (manager.failed || node < 2) return node;
    ushort cached = manager.rename_result[node];
    if (cached != 0) return cached - 1;
    uchar variable = manager.variable[node];
    if (variable < first_variable) { manager.failed = true; return 0; }
    ushort low = rename_recursive(manager, manager.low[node], first_variable);
    ushort high = rename_recursive(manager, manager.high[node], first_variable);
    ushort result = make_node(manager, variable - first_variable, low, high);
    if (!manager.failed) manager.rename_result[node] = (ushort)(result + 1);
    return result;
}

fn ushort evaluate(Manager* manager, ushort node, ushort assignment, uchar variable_count) {
    while (node >= 2) {
        uchar variable = manager.variable[node];
        uchar shift = variable_count - variable - 1;
        node = ((assignment >> shift) & 1) != 0 ? manager.high[node] : manager.low[node];
    }
    return node;
}

fn long bdd_symbolic_reachability(long* input, usz length)
    @export("bdd_symbolic_reachability") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n_raw = input[0], m_raw = input[1];
    long initial_raw = input[2], invariant_raw = input[3];
    if (n_raw < 1 || n_raw > 3 || m_raw < 0 || m_raw > 1) return -1;
    uchar n = (uchar)n_raw, m = (uchar)m_raw;
    usz state_count = (usz)1 << n;
    long state_mask = (1L << state_count) - 1;
    usz relation_length = (usz)1 << (2 * n + m);
    if (initial_raw < 0 || invariant_raw < 0 || (initial_raw & ~state_mask) != 0 ||
        (invariant_raw & ~state_mask) != 0 || length != 4 + relation_length) return -1;
    for (usz i = 0; i < relation_length; i++)
        if (input[4 + i] != 0 && input[4 + i] != 1) return -1;

    Manager manager = {};
    manager.next_id = 2;
    manager.variable_count = (uchar)(2 * n + m);
    ushort relation = truth_recursive(&manager, input + 4, 0, 0, manager.variable_count);
    if (manager.failed) return -1;
    ushort relation_end = manager.next_id;

    ushort reached_mask = (ushort)initial_raw;
    for (usz iteration = 0; iteration <= state_count; iteration++) {
        reset_round(&manager, relation_end);
        long[8] reached_bits = {};
        for (usz state = 0; state < state_count; state++)
            reached_bits[state] = (reached_mask >> state) & 1;
        ushort reached = truth_recursive(&manager, &reached_bits[0], 0, 0, n);
        ushort product = apply_binary(&manager, reached, relation, false);
        ushort next_set = exists_recursive(&manager, product, (uchar)(n + m));
        next_set = rename_recursive(&manager, next_set, (uchar)(n + m));
        ushort joined = apply_binary(&manager, reached, next_set, true);
        if (manager.failed) return -1;
        if (joined == reached) break;
        reached_mask = 0;
        for (usz state = 0; state < state_count; state++)
            reached_mask |= (ushort)(evaluate(&manager, joined, (ushort)state, n) << state);
        if (iteration == state_count) return -1;
    }
    ushort violation = (reached_mask & (ushort)~(ushort)invariant_raw) != 0 ? 1 : 0;
    return ((long)reached_mask << 1) | (long)violation;
}
