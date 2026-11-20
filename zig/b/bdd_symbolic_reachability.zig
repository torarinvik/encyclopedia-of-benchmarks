const MAX_INPUT: usize = 133;
const MAX_NODES: usize = 17000;
const UNIQUE_CAP: usize = 32768;
const UNIQUE_MASK: usize = UNIQUE_CAP - 1;

const Manager = struct {
    variable: [MAX_NODES]u8 = @splat(0),
    low: [MAX_NODES]u16 = @splat(0),
    high: [MAX_NODES]u16 = @splat(0),
    unique: [UNIQUE_CAP]u16 = @splat(0),
    next_id: usize = 2,
    variable_count: u8 = 0,
    failed: bool = false,
};

fn unique_hash(variable: u8, low: u16, high: u16) usize {
    return (@as(usize, variable) * 4099 + @as(usize, low) * 131 + @as(usize, high)) & UNIQUE_MASK;
}

fn make_node(manager: *Manager, variable: u8, low: u16, high: u16) u16 {
    if (low == high) return low;
    var slot = unique_hash(variable, low, high);
    for (0..UNIQUE_CAP) |_| {
        const encoded = manager.unique[slot];
        if (encoded == 0) {
            if (manager.next_id >= MAX_NODES) {
                manager.failed = true;
                return 0;
            }
            const id = manager.next_id;
            manager.variable[id] = variable;
            manager.low[id] = low;
            manager.high[id] = high;
            manager.unique[slot] = @intCast(id + 1);
            manager.next_id += 1;
            return @intCast(id);
        }
        const id: usize = @as(usize, encoded) - 1;
        if (manager.variable[id] == variable and manager.low[id] == low and manager.high[id] == high) return @intCast(id);
        slot = (slot + 1) & UNIQUE_MASK;
    }
    manager.failed = true;
    return 0;
}

fn reset_round(manager: *Manager, persistent_next: usize) void {
    @memset(&manager.unique, 0);
    manager.next_id = persistent_next;
    for (2..persistent_next) |id| {
        var slot = unique_hash(manager.variable[id], manager.low[id], manager.high[id]);
        while (manager.unique[slot] != 0) slot = (slot + 1) & UNIQUE_MASK;
        manager.unique[slot] = @intCast(id + 1);
    }
    manager.failed = false;
}

fn top_variable(manager: *const Manager, node: u16) u8 {
    return if (node < 2) manager.variable_count else manager.variable[node];
}

fn apply_recursive(manager: *Manager, left: u16, right: u16, is_or: bool) u16 {
    if (manager.failed) return 0;
    if (is_or) {
        if (left == 1 or right == 1) return 1;
        if (left == 0) return right;
        if (right == 0 or left == right) return left;
    } else {
        if (left == 0 or right == 0) return 0;
        if (left == 1) return right;
        if (right == 1 or left == right) return left;
    }
    const variable = @min(top_variable(manager, left), top_variable(manager, right));
    var left_low = left;
    var left_high = left;
    var right_low = right;
    var right_high = right;
    if (left >= 2 and manager.variable[left] == variable) {
        left_low = manager.low[left];
        left_high = manager.high[left];
    }
    if (right >= 2 and manager.variable[right] == variable) {
        right_low = manager.low[right];
        right_high = manager.high[right];
    }
    const low = apply_recursive(manager, left_low, right_low, is_or);
    const high = apply_recursive(manager, left_high, right_high, is_or);
    return make_node(manager, variable, low, high);
}

fn truth_table_recursive(manager: *Manager, input: [*c]const i64, offset: usize, variable: u8, prefix: usize, variable_count: u8) u16 {
    if (manager.failed) return 0;
    if (variable == variable_count) return @intCast(input[offset + prefix]);
    const low = truth_table_recursive(manager, input, offset, variable + 1, prefix * 2, variable_count);
    const high = truth_table_recursive(manager, input, offset, variable + 1, prefix * 2 + 1, variable_count);
    return make_node(manager, variable, low, high);
}

fn state_set_recursive(manager: *Manager, mask: u16, variable: u8, prefix: usize, variable_count: u8) u16 {
    if (manager.failed) return 0;
    if (variable == variable_count) return (mask >> @intCast(prefix)) & 1;
    const low = state_set_recursive(manager, mask, variable + 1, prefix * 2, variable_count);
    const high = state_set_recursive(manager, mask, variable + 1, prefix * 2 + 1, variable_count);
    return make_node(manager, variable, low, high);
}

fn exists_recursive(manager: *Manager, node: u16, quantified_variables: u8) u16 {
    if (manager.failed or node < 2) return node;
    const variable = manager.variable[node];
    const low = exists_recursive(manager, manager.low[node], quantified_variables);
    const high = exists_recursive(manager, manager.high[node], quantified_variables);
    if (variable < quantified_variables) return apply_recursive(manager, low, high, true);
    return make_node(manager, variable, low, high);
}

fn rename_recursive(manager: *Manager, node: u16, first_variable: u8) u16 {
    if (manager.failed or node < 2) return node;
    const variable = manager.variable[node];
    if (variable < first_variable) {
        manager.failed = true;
        return 0;
    }
    const low = rename_recursive(manager, manager.low[node], first_variable);
    const high = rename_recursive(manager, manager.high[node], first_variable);
    return make_node(manager, variable - first_variable, low, high);
}

fn evaluate(manager: *const Manager, root: u16, assignment: u16, variable_count: u8) u16 {
    var node = root;
    while (node >= 2) {
        const variable = manager.variable[node];
        const shift = variable_count - variable - 1;
        node = if (((assignment >> shift) & 1) != 0) manager.high[node] else manager.low[node];
    }
    return node;
}

export fn bdd_symbolic_reachability(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT) return -1;
    const n_raw = input[0];
    const m_raw = input[1];
    const initial_raw = input[2];
    const invariant_raw = input[3];
    if (n_raw < 1 or n_raw > 3 or m_raw < 0 or m_raw > 1) return -1;
    const n: usize = @intCast(n_raw);
    const m: usize = @intCast(m_raw);
    const state_count: usize = @as(usize, 1) << @intCast(n);
    const state_mask: i64 = (@as(i64, 1) << @intCast(state_count)) - 1;
    const relation_length: usize = @as(usize, 1) << @intCast(2 * n + m);
    if (initial_raw < 0 or invariant_raw < 0 or (initial_raw >> @intCast(state_count)) != 0 or (invariant_raw >> @intCast(state_count)) != 0 or length != 4 + relation_length) return -1;
    for (0..relation_length) |i| if (input[4 + i] != 0 and input[4 + i] != 1) return -1;

    var manager = Manager{ .variable_count = @intCast(2 * n + m) };
    const relation = truth_table_recursive(&manager, input, 4, 0, 0, manager.variable_count);
    if (manager.failed) return -1;
    const persistent_next = manager.next_id;
    var reached_mask: u16 = @intCast(initial_raw & state_mask);
    for (0..state_count + 1) |iteration| {
        reset_round(&manager, persistent_next);
        const reached = state_set_recursive(&manager, reached_mask, 0, 0, @intCast(n));
        const product = apply_recursive(&manager, reached, relation, false);
        const next_set = exists_recursive(&manager, product, @intCast(n + m));
        const current_set = rename_recursive(&manager, next_set, @intCast(n + m));
        const joined = apply_recursive(&manager, reached, current_set, true);
        if (manager.failed) return -1;
        if (joined == reached) break;
        reached_mask = 0;
        for (0..state_count) |state| {
            reached_mask |= evaluate(&manager, joined, @intCast(state), @intCast(n)) << @intCast(state);
        }
        if (iteration == state_count) return -1;
    }
    const violation = (reached_mask & ~@as(u16, @intCast(invariant_raw))) != 0;
    return (@as(i64, reached_mask) << 1) | @as(i64, @intFromBool(violation));
}
