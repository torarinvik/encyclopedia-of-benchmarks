from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_KEY_LENGTH = 6
comptime RECORD_WIDTH = 9
comptime MAX_INPUT_VALUES = 577
comptime MAX_PARSEABLE_INPUT_VALUES = 578
comptime MAX_NODES = 384

struct TstNode(Copyable):
    var character: Int64
    var left: Int
    var middle: Int
    var right: Int
    var value: Int64
    var present: Bool

    fn __init__(out self):
        self.character = 0
        self.left = 0
        self.middle = 0
        self.right = 0
        self.value = 0
        self.present = False

struct TstState:
    var nodes: InlineArray[TstNode, MAX_NODES + 1]
    var node_count: Int
    var root: Int
    var size: Int

    fn __init__(out self):
        self.nodes = InlineArray[TstNode, MAX_NODES + 1](fill=TstNode())
        self.node_count = 0
        self.root = 0
        self.size = 0

fn tst_put(inout state: TstState, node_id: Int, key: InlineArray[Int64, MAX_KEY_LENGTH],
           length: Int, depth: Int, value: Int64, inout old_value: Int64) -> Int:
    var current = node_id
    if current == 0:
        state.node_count += 1
        current = state.node_count
        state.nodes[current].character = key[depth]
    if key[depth] < state.nodes[current].character:
        let child = tst_put(state, state.nodes[current].left, key, length, depth,
                           value, old_value)
        state.nodes[current].left = child
    elif key[depth] > state.nodes[current].character:
        let child = tst_put(state, state.nodes[current].right, key, length, depth,
                            value, old_value)
        state.nodes[current].right = child
    elif depth + 1 < length:
        let child = tst_put(state, state.nodes[current].middle, key, length,
                            depth + 1, value, old_value)
        state.nodes[current].middle = child
    else:
        old_value = state.nodes[current].value if state.nodes[current].present else 0
        if not state.nodes[current].present:
            state.size += 1
        state.nodes[current].value = value
        state.nodes[current].present = True
    return current

fn tst_find(state: TstState, node_id: Int, key: InlineArray[Int64, MAX_KEY_LENGTH],
            length: Int) -> Int:
    var current = node_id
    var depth = 0
    while current != 0:
        if key[depth] < state.nodes[current].character:
            current = state.nodes[current].left
        elif key[depth] > state.nodes[current].character:
            current = state.nodes[current].right
        elif depth + 1 == length:
            return current
        else:
            current = state.nodes[current].middle
            depth += 1
    return 0

fn tst_delete(inout state: TstState, node_id: Int,
              key: InlineArray[Int64, MAX_KEY_LENGTH], length: Int, depth: Int,
              inout removed: Int64) -> Int:
    if node_id == 0:
        return 0
    if key[depth] < state.nodes[node_id].character:
        let child = tst_delete(state, state.nodes[node_id].left, key, length,
                               depth, removed)
        state.nodes[node_id].left = child
    elif key[depth] > state.nodes[node_id].character:
        let child = tst_delete(state, state.nodes[node_id].right, key, length,
                               depth, removed)
        state.nodes[node_id].right = child
    elif depth + 1 < length:
        let child = tst_delete(state, state.nodes[node_id].middle, key, length,
                               depth + 1, removed)
        state.nodes[node_id].middle = child
    elif state.nodes[node_id].present:
        removed = state.nodes[node_id].value
        state.nodes[node_id].value = 0
        state.nodes[node_id].present = False
        state.size -= 1
    if not state.nodes[node_id].present and state.nodes[node_id].left == 0 and
       state.nodes[node_id].middle == 0 and state.nodes[node_id].right == 0:
        return 0
    return node_id

fn tst_count(state: TstState, node_id: Int) -> Int:
    if node_id == 0:
        return 0
    return (1 if state.nodes[node_id].present else 0) +
        tst_count(state, state.nodes[node_id].left) +
        tst_count(state, state.nodes[node_id].middle) +
        tst_count(state, state.nodes[node_id].right)

fn tst_matches(state: TstState, node_id: Int,
               pattern: InlineArray[Int64, MAX_KEY_LENGTH],
               length: Int, depth: Int) -> Int:
    if node_id == 0:
        return 0
    let token = pattern[depth]
    if token == 46:
        let here = (1 if state.nodes[node_id].present else 0) if depth + 1 == length else
            tst_matches(state, state.nodes[node_id].middle, pattern, length, depth + 1)
        return tst_matches(state, state.nodes[node_id].left, pattern, length, depth) +
            here + tst_matches(state, state.nodes[node_id].right, pattern, length, depth)
    if token < state.nodes[node_id].character:
        return tst_matches(state, state.nodes[node_id].left, pattern, length, depth)
    if token > state.nodes[node_id].character:
        return tst_matches(state, state.nodes[node_id].right, pattern, length, depth)
    if depth + 1 == length:
        return 1 if state.nodes[node_id].present else 0
    return tst_matches(state, state.nodes[node_id].middle, pattern, length, depth + 1)

fn tst_valid_input(input: UnsafePointer[Int64, ImmutAnyOrigin],
                   length: c_size_t) -> Int:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or
       length > MAX_PARSEABLE_INPUT_VALUES:
        return -1
    if input[0] < 0 or input[0] > MAX_OPERATIONS:
        return -1
    let operation_count = Int(input[0])
    if length != c_size_t(1 + operation_count * RECORD_WIDTH):
        return -1
    for operation in range(operation_count):
        let base = 1 + operation * RECORD_WIDTH
        let opcode = input[base]
        let key_length = input[base + 1]
        if opcode < 0 or opcode > 6 or key_length < 0 or key_length > MAX_KEY_LENGTH:
            return -1
        if (opcode <= 2 and key_length == 0) or (opcode == 6 and key_length != 0):
            return -1
        for index in range(MAX_KEY_LENGTH):
            let character = input[base + 2 + index]
            if index < key_length:
                if not ((character >= 97 and character <= 122) or
                        (opcode == 5 and character == 46)):
                    return -1
            elif character != 0:
                return -1
        let value = input[base + RECORD_WIDTH - 1]
        if opcode == 0:
            if value < 1 or value > 65535:
                return -1
        elif value != 0:
            return -1
    return operation_count

@export("ternary_search_trie")
fn ternary_search_trie(input: UnsafePointer[Int64, ImmutAnyOrigin],
                       length: c_size_t) abi("C") -> Int64:
    let operation_count = tst_valid_input(input, length)
    if operation_count < 0:
        return -1
    var state = TstState()
    var total: Int64 = 0
    for operation in range(operation_count):
        let base = 1 + operation * RECORD_WIDTH
        let opcode = input[base]
        let key_length = Int(input[base + 1])
        var key = InlineArray[Int64, MAX_KEY_LENGTH](fill=0)
        for index in range(MAX_KEY_LENGTH):
            key[index] = input[base + 2 + index]
        let value = input[base + RECORD_WIDTH - 1]
        var observed: Int64 = 0
        if opcode == 0:
            state.root = tst_put(state, state.root, key, key_length, 0, value, observed)
        elif opcode == 1:
            let found = tst_find(state, state.root, key, key_length)
            if found != 0 and state.nodes[found].present:
                observed = state.nodes[found].value
        elif opcode == 2:
            state.root = tst_delete(state, state.root, key, key_length, 0, observed)
        elif opcode == 3:
            var current = state.root
            var depth = 0
            while current != 0 and depth < key_length:
                if key[depth] < state.nodes[current].character:
                    current = state.nodes[current].left
                elif key[depth] > state.nodes[current].character:
                    current = state.nodes[current].right
                else:
                    depth += 1
                    if state.nodes[current].present:
                        observed = Int64(depth)
                    current = state.nodes[current].middle
        elif opcode == 4:
            if key_length == 0:
                observed = Int64(state.size)
            else:
                let found = tst_find(state, state.root, key, key_length)
                if found != 0:
                    observed = (1 if state.nodes[found].present else 0) +
                        tst_count(state, state.nodes[found].middle)
        elif opcode == 5 and key_length != 0:
            observed = Int64(tst_matches(state, state.root, key, key_length, 0))
        elif opcode == 6:
            observed = Int64(state.size)
        total += Int64(operation + 1) * observed
    return total
