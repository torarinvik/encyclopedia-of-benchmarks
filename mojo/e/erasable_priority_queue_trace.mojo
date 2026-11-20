from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_Q = 63
comptime MAX_PARSEABLE_INPUT = 128
comptime VALUE_OFFSET = 100
comptime VALUE_COUNT = 201

fn epq_less(left: Int, right: Int,
        values: InlineArray[Int64, MAX_Q]) -> Bool:
    if values[left] < values[right]: return True
    if values[left] > values[right]: return False
    return left < right

fn epq_heap_push(inout heap: InlineArray[Int, MAX_Q], inout heap_size: Int,
        item: Int, values: InlineArray[Int64, MAX_Q]):
    var index = heap_size
    heap_size += 1
    while index > 0:
        let parent = (index - 1) // 2
        if not epq_less(item, heap[parent], values): break
        heap[index] = heap[parent]
        index = parent
    heap[index] = item

fn epq_heap_pop(inout heap: InlineArray[Int, MAX_Q], inout heap_size: Int,
        values: InlineArray[Int64, MAX_Q]) -> Int:
    let result = heap[0]
    heap_size -= 1
    if heap_size == 0: return result
    let last = heap[heap_size]
    var index = 0
    while True:
        let left = 2 * index + 1
        if left >= heap_size: break
        let right = left + 1
        var child = left
        if right < heap_size and epq_less(heap[right], heap[left], values):
            child = right
        if not epq_less(heap[child], last, values): break
        heap[index] = heap[child]
        index = child
    heap[index] = last
    return result

fn epq_normalize(inout live: InlineArray[Int, MAX_Q], inout live_size: Int,
        inout deleted: InlineArray[Int, MAX_Q], inout deleted_size: Int,
        values: InlineArray[Int64, MAX_Q]):
    while live_size > 0 and deleted_size > 0 and live[0] == deleted[0]:
        let removed_live = epq_heap_pop(inout live, inout live_size, values)
        let removed_deleted = epq_heap_pop(inout deleted, inout deleted_size, values)
        if removed_live != removed_deleted: return

@export("erasable_priority_queue_trace")
fn erasable_priority_queue_trace(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_INPUT:
        return -1
    let raw_q = input[0]
    if raw_q < 0 or raw_q > MAX_Q: return -1
    let q = Int(raw_q)
    if length != c_size_t(1 + 2 * q): return -1

    var values = InlineArray[Int64, MAX_Q](fill=0)
    var counts = InlineArray[Int, VALUE_COUNT](fill=0)
    var active = InlineArray[Bool, MAX_Q](fill=False)
    var live = InlineArray[Int, MAX_Q](fill=0)
    var deleted = InlineArray[Int, MAX_Q](fill=0)
    var live_size = 0
    var deleted_size = 0
    var inserted = 0
    var score: Int64 = 0

    for operation in range(q):
        let opcode = input[1 + 2 * operation]
        let operand = input[2 + 2 * operation]
        if opcode < 0 or opcode > 3 or operand < -100 or operand > 100: return -1
        epq_normalize(inout live, inout live_size, inout deleted,
            inout deleted_size, values)

        var response: Int64 = 0
        if opcode == 0:
            let id = inserted
            values[id] = operand
            active[id] = True
            counts[Int(operand + VALUE_OFFSET)] += 1
            epq_heap_push(inout live, inout live_size, id, values)
            inserted += 1
            epq_normalize(inout live, inout live_size, inout deleted,
                inout deleted_size, values)
        elif opcode == 1:
            let key = Int(operand + VALUE_OFFSET)
            if counts[key] == 0: return -1
            var found = inserted
            for candidate in range(inserted):
                if active[candidate] and values[candidate] == operand:
                    found = candidate
                    break
            if found == inserted: return -1
            active[found] = False
            counts[key] -= 1
            epq_heap_push(inout deleted, inout deleted_size, found, values)
            response = 1
            epq_normalize(inout live, inout live_size, inout deleted,
                inout deleted_size, values)
        elif opcode == 2:
            if operand != 0: return -1
            if live_size == 0: response = -101
            else: response = values[live[0]]
        else:
            if operand != 0 or live_size == 0: return -1
            let id = epq_heap_pop(inout live, inout live_size, values)
            active[id] = False
            let key = Int(values[id] + VALUE_OFFSET)
            counts[key] -= 1
            response = values[id]

        let token = opcode * 202 + response + 101
        score += Int64(operation + 1) * token
    return score
