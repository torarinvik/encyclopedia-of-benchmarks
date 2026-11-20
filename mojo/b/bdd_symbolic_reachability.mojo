from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_INPUT = 133
alias MAX_NODES = 17000
alias UNIQUE_CAP = 32768
alias UNIQUE_MASK = UNIQUE_CAP - 1

@fieldwise_init
struct BddManager(Copyable):
    var variable: InlineArray[UInt8, MAX_NODES]
    var low: InlineArray[UInt16, MAX_NODES]
    var high: InlineArray[UInt16, MAX_NODES]
    var unique: InlineArray[UInt16, UNIQUE_CAP]
    var next_id: Int
    var variable_count: UInt8
    var failed: Bool

fn unique_hash(variable: UInt8, low: UInt16, high: UInt16) -> Int:
    return (Int(variable) * 4099 + Int(low) * 131 + Int(high)) & UNIQUE_MASK

fn make_node(inout manager: BddManager, variable: UInt8, low: UInt16, high: UInt16) -> UInt16:
    if low == high: return low
    var slot = unique_hash(variable, low, high)
    for _ in range(UNIQUE_CAP):
        let encoded = manager.unique[slot]
        if encoded == 0:
            if manager.next_id >= MAX_NODES:
                manager.failed = True
                return 0
            let id = manager.next_id
            manager.variable[id] = variable
            manager.low[id] = low
            manager.high[id] = high
            manager.unique[slot] = UInt16(id + 1)
            manager.next_id += 1
            return UInt16(id)
        let id = Int(encoded) - 1
        if manager.variable[id] == variable and manager.low[id] == low and manager.high[id] == high:
            return UInt16(id)
        slot = (slot + 1) & UNIQUE_MASK
    manager.failed = True
    return 0

fn reset_round(inout manager: BddManager, persistent_next: Int):
    for slot in range(UNIQUE_CAP): manager.unique[slot] = 0
    manager.next_id = persistent_next
    for id in range(2, persistent_next):
        var slot = unique_hash(manager.variable[id], manager.low[id], manager.high[id])
        while manager.unique[slot] != 0: slot = (slot + 1) & UNIQUE_MASK
        manager.unique[slot] = UInt16(id + 1)
    manager.failed = False

fn top_variable(inout manager: BddManager, node: UInt16) -> UInt8:
    if node < 2: return manager.variable_count
    return manager.variable[node]

fn apply_recursive(inout manager: BddManager, left: UInt16, right: UInt16, is_or: Bool) -> UInt16:
    if manager.failed: return 0
    if is_or:
        if left == 1 or right == 1: return 1
        if left == 0: return right
        if right == 0 or left == right: return left
    else:
        if left == 0 or right == 0: return 0
        if left == 1: return right
        if right == 1 or left == right: return left
    var variable = top_variable(inout manager, left)
    let right_variable = top_variable(inout manager, right)
    if right_variable < variable: variable = right_variable
    var left_low = left
    var left_high = left
    var right_low = right
    var right_high = right
    if left >= 2 and manager.variable[Int(left)] == variable:
        left_low = manager.low[Int(left)]
        left_high = manager.high[Int(left)]
    if right >= 2 and manager.variable[Int(right)] == variable:
        right_low = manager.low[Int(right)]
        right_high = manager.high[Int(right)]
    let low = apply_recursive(inout manager, left_low, right_low, is_or)
    let high = apply_recursive(inout manager, left_high, right_high, is_or)
    return make_node(inout manager, variable, low, high)

fn truth_table_recursive(inout manager: BddManager, input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int,
                         variable: UInt8, prefix: Int, variable_count: UInt8) -> UInt16:
    if manager.failed: return 0
    if variable == variable_count: return UInt16(input[offset + prefix])
    let low = truth_table_recursive(inout manager, input, offset, variable + 1, prefix * 2, variable_count)
    let high = truth_table_recursive(inout manager, input, offset, variable + 1, prefix * 2 + 1, variable_count)
    return make_node(inout manager, variable, low, high)

fn state_set_recursive(inout manager: BddManager, mask: UInt16, variable: UInt8, prefix: Int,
                       variable_count: UInt8) -> UInt16:
    if manager.failed: return 0
    if variable == variable_count: return (mask >> prefix) & 1
    let low = state_set_recursive(inout manager, mask, variable + 1, prefix * 2, variable_count)
    let high = state_set_recursive(inout manager, mask, variable + 1, prefix * 2 + 1, variable_count)
    return make_node(inout manager, variable, low, high)

fn exists_recursive(inout manager: BddManager, node: UInt16, quantified_variables: UInt8) -> UInt16:
    if manager.failed or node < 2: return node
    let variable = manager.variable[Int(node)]
    let low_child = manager.low[Int(node)]
    let high_child = manager.high[Int(node)]
    let low = exists_recursive(inout manager, low_child, quantified_variables)
    let high = exists_recursive(inout manager, high_child, quantified_variables)
    if variable < quantified_variables: return apply_recursive(inout manager, low, high, True)
    return make_node(inout manager, variable, low, high)

fn rename_recursive(inout manager: BddManager, node: UInt16, first_variable: UInt8) -> UInt16:
    if manager.failed or node < 2: return node
    let variable = manager.variable[Int(node)]
    if variable < first_variable:
        manager.failed = True
        return 0
    let low_child = manager.low[Int(node)]
    let high_child = manager.high[Int(node)]
    let low = rename_recursive(inout manager, low_child, first_variable)
    let high = rename_recursive(inout manager, high_child, first_variable)
    return make_node(inout manager, variable - first_variable, low, high)

fn evaluate(inout manager: BddManager, root: UInt16, assignment: UInt16, variable_count: UInt8) -> UInt16:
    var node = root
    while node >= 2:
        let variable = manager.variable[Int(node)]
        let shift = variable_count - variable - 1
        if ((assignment >> shift) & 1) != 0: node = manager.high[Int(node)]
        else: node = manager.low[Int(node)]
    return node

@export("bdd_symbolic_reachability")
fn bdd_symbolic_reachability(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT: return -1
    let n_raw = input[0]
    let m_raw = input[1]
    let initial_raw = input[2]
    let invariant_raw = input[3]
    if n_raw < 1 or n_raw > 3 or m_raw < 0 or m_raw > 1: return -1
    let n = Int(n_raw)
    let m = Int(m_raw)
    let state_count = 1 << n
    let state_mask = (1 << state_count) - 1
    let relation_length = 1 << (2 * n + m)
    if initial_raw < 0 or invariant_raw < 0 or (initial_raw >> state_count) != 0 or
       (invariant_raw >> state_count) != 0 or length != c_size_t(4 + relation_length): return -1
    for i in range(relation_length):
        if input[4 + i] != 0 and input[4 + i] != 1: return -1

    var manager = BddManager(InlineArray[UInt8, MAX_NODES](), InlineArray[UInt16, MAX_NODES](),
        InlineArray[UInt16, MAX_NODES](), InlineArray[UInt16, UNIQUE_CAP](), 2,
        UInt8(2 * n + m), False)
    let relation = truth_table_recursive(inout manager, input, 4, 0, 0, manager.variable_count)
    if manager.failed: return -1
    let persistent_next = manager.next_id
    var reached_mask = UInt16(initial_raw & Int64(state_mask))
    for iteration in range(state_count + 1):
        reset_round(inout manager, persistent_next)
        let reached = state_set_recursive(inout manager, reached_mask, 0, 0, UInt8(n))
        let product = apply_recursive(inout manager, reached, relation, False)
        let next_set = exists_recursive(inout manager, product, UInt8(n + m))
        let current_set = rename_recursive(inout manager, next_set, UInt8(n + m))
        let joined = apply_recursive(inout manager, reached, current_set, True)
        if manager.failed: return -1
        if joined == reached: break
        reached_mask = 0
        for state in range(state_count):
            reached_mask |= evaluate(inout manager, joined, UInt16(state), UInt8(n)) << state
        if iteration == state_count: return -1
    let violation = (reached_mask & ~UInt16(invariant_raw)) != 0
    let violation_bit = 1 if violation else 0
    return (Int64(reached_mask) << 1) | Int64(violation_bit)
