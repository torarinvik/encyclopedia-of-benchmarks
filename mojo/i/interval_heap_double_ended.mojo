from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime IH_MAX_INITIAL = 64
comptime IH_MAX_OPERATIONS = 128
comptime IH_MAX_KEYS = IH_MAX_INITIAL + IH_MAX_OPERATIONS
comptime IH_MAX_INPUT = IH_MAX_INITIAL + 2 + 2 * IH_MAX_OPERATIONS

fn ih_high(keys: InlineArray[Int32, IH_MAX_KEYS], count: Int, node: Int) -> Int:
    let high = 2 * node + 1
    return high if high < count else 2 * node

fn ih_sift_up_low(mut keys: InlineArray[Int32, IH_MAX_KEYS], start: Int):
    var node = start
    while node > 0:
        let parent = (node - 1) // 2
        let low = 2 * node
        let parent_low = 2 * parent
        if keys[low] >= keys[parent_low]: return
        let temporary = keys[low]
        keys[low] = keys[parent_low]
        keys[parent_low] = temporary
        node = parent

fn ih_sift_up_high(mut keys: InlineArray[Int32, IH_MAX_KEYS], count: Int, start: Int):
    var node = start
    while node > 0:
        let parent = (node - 1) // 2
        let high = ih_high(keys, count, node)
        let parent_high = ih_high(keys, count, parent)
        if keys[high] <= keys[parent_high]: return
        let temporary = keys[high]
        keys[high] = keys[parent_high]
        keys[parent_high] = temporary
        node = parent

fn ih_insert(mut keys: InlineArray[Int32, IH_MAX_KEYS], mut count: Int&, value: Int32):
    let key_index = count
    keys[key_index] = value
    count += 1
    let node = key_index // 2
    if key_index % 2 == 1 and keys[key_index] < keys[key_index - 1]:
        let temporary = keys[key_index]
        keys[key_index] = keys[key_index - 1]
        keys[key_index - 1] = temporary
    ih_sift_up_low(mut keys, node)
    ih_sift_up_high(mut keys, count, node)

fn ih_extract_min(mut keys: InlineArray[Int32, IH_MAX_KEYS], mut count: Int&) -> Int32:
    let result = keys[0]
    count -= 1
    let last = keys[count]
    if count == 0: return result
    keys[0] = last
    var node = 0
    while True:
        let left = 2 * node + 1
        if 2 * left >= count: return result
        let right = left + 1
        var child = left
        if 2 * right < count and keys[2 * right] < keys[2 * left]: child = right
        let node_low = 2 * node
        let child_low = 2 * child
        if keys[child_low] >= keys[node_low]: return result
        let temporary = keys[node_low]
        keys[node_low] = keys[child_low]
        keys[child_low] = temporary
        let child_high = ih_high(keys, count, child)
        if keys[child_high] < keys[child_low]:
            let pair_temporary = keys[child_high]
            keys[child_high] = keys[child_low]
            keys[child_low] = pair_temporary
        node = child
    result

fn ih_extract_max(mut keys: InlineArray[Int32, IH_MAX_KEYS], mut count: Int&) -> Int32:
    if count <= 2:
        count -= 1
        return keys[count]
    let result = keys[1]
    count -= 1
    keys[1] = keys[count]
    var node = 0
    while True:
        let left = 2 * node + 1
        if 2 * left >= count: return result
        let right = left + 1
        var child = left
        if 2 * right < count and keys[ih_high(keys, count, left)] < keys[ih_high(keys, count, right)]: child = right
        let node_high = ih_high(keys, count, node)
        let child_high = ih_high(keys, count, child)
        if keys[node_high] >= keys[child_high]: return result
        let temporary = keys[node_high]
        keys[node_high] = keys[child_high]
        keys[child_high] = temporary
        let child_low = 2 * child
        if keys[child_high] < keys[child_low]:
            let pair_temporary = keys[child_high]
            keys[child_high] = keys[child_low]
            keys[child_low] = pair_temporary
        node = child
    result

fn ih_sort(mut values: InlineArray[Int32, IH_MAX_KEYS], count: Int):
    for index in range(1, count):
        let value = values[index]
        var position = index
        while position > 0 and values[position - 1] > value:
            values[position] = values[position - 1]
            position -= 1
        values[position] = value

fn ih_write_i64(out: UnsafePointer[UInt8, MutAnyOrigin], mut position: Int&, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        out[position] = UInt8((bits >> (8 * byte)) & UInt64(255))
        position += 1

@export("interval_heap_double_ended")
fn interval_heap_double_ended(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                              out: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(IH_MAX_INPUT): return -1
    let input_length = Int(length)
    if input[0] < 0 or input[0] > IH_MAX_INITIAL: return -1
    let initial_count = Int(input[0])
    if input_length < initial_count + 2: return -1
    if input[initial_count + 1] < 0 or input[initial_count + 1] > IH_MAX_OPERATIONS: return -1
    let operation_count = Int(input[initial_count + 1])
    if input_length != initial_count + 2 + 2 * operation_count: return -1
    for index in range(initial_count):
        if input[index + 1] < -2147483648 or input[index + 1] > 2147483647: return -1
    for op in range(operation_count):
        let opcode = input[initial_count + 2 + 2 * op]
        let argument = input[initial_count + 3 + 2 * op]
        if opcode < 0 or opcode > 5: return -1
        if opcode == 0:
            if argument < -2147483648 or argument > 2147483647: return -1
        elif argument != 0: return -1

    var keys = InlineArray[Int32, IH_MAX_KEYS](fill=0)
    var count = 0
    for index in range(initial_count): ih_insert(mut keys, mut count, Int32(input[index + 1]))
    var events = InlineArray[Int64, IH_MAX_OPERATIONS](fill=0)
    var event_count = 0
    for op in range(operation_count):
        let opcode = input[initial_count + 2 + 2 * op]
        let argument = Int32(input[initial_count + 3 + 2 * op])
        if opcode == 0: ih_insert(mut keys, mut count, argument)
        elif opcode == 1:
            if count == 0: return -1
            events[event_count] = Int64(keys[0]); event_count += 1
        elif opcode == 2:
            if count == 0: return -1
            events[event_count] = Int64(keys[ih_high(keys, count, 0)]); event_count += 1
        elif opcode == 3:
            if count == 0: return -1
            events[event_count] = Int64(ih_extract_min(mut keys, mut count)); event_count += 1
        elif opcode == 4:
            if count == 0: return -1
            events[event_count] = Int64(ih_extract_max(mut keys, mut count)); event_count += 1
        else: events[event_count] = Int64(count); event_count += 1

    var sorted = keys
    ih_sort(mut sorted, count)
    let required = (2 + event_count + count) * 8
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var position = 0
    ih_write_i64(out, mut position, Int64(event_count))
    for index in range(event_count): ih_write_i64(out, mut position, events[index])
    ih_write_i64(out, mut position, Int64(count))
    for index in range(count): ih_write_i64(out, mut position, Int64(sorted[index]))
    Int64(required)
