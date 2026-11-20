from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_OPS = 48
comptime HANDLES = 8
comptime MAX_INPUT = 146

fn store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & UInt64(255))

@export("cactus_stack_branch_trace")
fn cactus_stack_branch_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_INPUT:
        return -1
    let q_value = input[0]
    if q_value < 0 or q_value > MAX_OPS or Int(length) != 1 + 3 * Int(q_value):
        return -1
    let q = Int(q_value)
    for i in range(q):
        let op = input[1 + 3 * i]
        let a = input[2 + 3 * i]
        let b = input[3 + 3 * i]
        if op == 0:
            if a < 0 or a >= HANDLES or b < -1000 or b > 1000: return -1
        elif op >= 1 and op <= 3:
            if a < 0 or a >= HANDLES or b != 0: return -1
        elif op == 4:
            if a < 0 or a >= HANDLES or b < 0 or b >= HANDLES: return -1
        else:
            return -1

    var node_value = InlineArray[Int64, MAX_OPS](fill=0)
    var node_next = InlineArray[Int, MAX_OPS](fill=-1)
    var node_kind = InlineArray[Int, MAX_OPS](fill=0)
    var node_live = InlineArray[Bool, MAX_OPS](fill=False)
    var heads = InlineArray[Int, HANDLES](fill=-1)
    var branch_child = InlineArray[Int, HANDLES](fill=-1)
    var attached_owner = InlineArray[Int, HANDLES](fill=-1)
    var wrapper_for_child = InlineArray[Int, HANDLES](fill=-1)
    var statuses = InlineArray[Int64, MAX_OPS](fill=0)
    var results = InlineArray[Int64, MAX_OPS](fill=0)
    var node_count = 0

    for i in range(q):
        let op = Int(input[1 + 3 * i])
        let a = Int(input[2 + 3 * i])
        let b = input[3 + 3 * i]
        var head = heads[a]
        while head >= 0 and node_kind[head] == 1 and not node_live[head]:
            head = node_next[head]
        heads[a] = head
        statuses[i] = 1
        if op == 0:
            node_value[node_count] = b
            node_next[node_count] = head
            node_kind[node_count] = 0
            node_live[node_count] = False
            heads[a] = node_count
            node_count += 1
        elif op == 1:
            if head < 0 or (node_kind[head] == 1 and node_live[head]):
                statuses[i] = 0
            else:
                results[i] = node_value[head]
                var next_head = node_next[head]
                while next_head >= 0 and node_kind[next_head] == 1 and not node_live[next_head]:
                    next_head = node_next[next_head]
                heads[a] = next_head
                if next_head < 0 and attached_owner[a] >= 0:
                    let owner = attached_owner[a]
                    node_live[wrapper_for_child[a]] = False
                    branch_child[owner] = -1
                    attached_owner[a] = -1
                    wrapper_for_child[a] = -1
        elif op == 2:
            var top = head
            while top >= 0 and node_kind[top] == 1:
                top = node_next[top]
                while top >= 0 and node_kind[top] == 1 and not node_live[top]:
                    top = node_next[top]
            if top < 0: statuses[i] = 0
            else: results[i] = node_value[top]
        elif op == 3:
            if head >= 0 and node_kind[head] == 1 and node_live[head]: results[i] = 1
        else:
            let child = Int(b)
            var child_head = heads[child]
            while child_head >= 0 and node_kind[child_head] == 1 and not node_live[child_head]:
                child_head = node_next[child_head]
            heads[child] = child_head
            var owner_top = head
            while owner_top >= 0 and node_kind[owner_top] == 1:
                owner_top = node_next[owner_top]
                while owner_top >= 0 and node_kind[owner_top] == 1 and not node_live[owner_top]:
                    owner_top = node_next[owner_top]
            if a == child or owner_top < 0 or attached_owner[a] >= 0 or branch_child[a] >= 0 or attached_owner[child] >= 0 or branch_child[child] >= 0:
                return -1
            if child_head < 0:
                results[i] = 0
            else:
                node_value[node_count] = 0
                node_next[node_count] = head
                node_kind[node_count] = 1
                node_live[node_count] = True
                let wrapper = node_count
                node_count += 1
                heads[a] = wrapper
                branch_child[a] = child
                attached_owner[child] = a
                wrapper_for_child[child] = wrapper
                results[i] = 1

    let required = 16 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or Int(capacity) < required: return -2
    for i in range(q):
        store_i64(output, 16 * i, statuses[i])
        store_i64(output, 16 * i + 8, results[i])
    return Int64(required)
