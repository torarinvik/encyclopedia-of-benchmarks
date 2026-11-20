from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 24
comptime RECORD_WIDTH = 3
comptime MAX_PARSEABLE_INPUT_VALUES = 74
comptime MAX_INTERVALS = 25
comptime DOMAIN_END = 32

struct Interval(Copyable):
    var left: Int64
    var right: Int64

    fn __init__(out self):
        self.left = 0
        self.right = 0

struct IntervalState:
    var items: InlineArray[Interval, MAX_INTERVALS]
    var count: Int

    fn __init__(out self):
        self.items = InlineArray[Interval, MAX_INTERVALS](fill=Interval())
        self.count = 0

fn add_interval(inout state: IntervalState, left_input: Int64, right_input: Int64):
    if left_input == right_input:
        return
    var left = left_input
    var right = right_input
    var next = InlineArray[Interval, MAX_INTERVALS](fill=Interval())
    var out_count = 0
    var inserted = False
    for index in range(state.count):
        let current = state.items[index]
        if current.right < left:
            next[out_count] = current
            out_count += 1
        elif right < current.left:
            if not inserted:
                var merged = Interval()
                merged.left = left
                merged.right = right
                next[out_count] = merged
                out_count += 1
                inserted = True
            next[out_count] = current
            out_count += 1
        else:
            if current.left < left:
                left = current.left
            if current.right > right:
                right = current.right
    if not inserted:
        var merged = Interval()
        merged.left = left
        merged.right = right
        next[out_count] = merged
        out_count += 1
    for index in range(out_count):
        state.items[index] = next[index]
    state.count = out_count

fn remove_interval(inout state: IntervalState, left: Int64, right: Int64):
    if left == right:
        return
    var next = InlineArray[Interval, MAX_INTERVALS + 1](fill=Interval())
    var out_count = 0
    for index in range(state.count):
        let current = state.items[index]
        if current.right <= left or current.left >= right:
            next[out_count] = current
            out_count += 1
        else:
            if current.left < left:
                var keep = Interval()
                keep.left = current.left
                keep.right = left
                next[out_count] = keep
                out_count += 1
            if current.right > right:
                var keep = Interval()
                keep.left = right
                keep.right = current.right
                next[out_count] = keep
                out_count += 1
    for index in range(out_count):
        state.items[index] = next[index]
    state.count = out_count

fn covered_length(state: IntervalState) -> Int64:
    var total: Int64 = 0
    for index in range(state.count):
        total += state.items[index].right - state.items[index].left
    return total

fn valid_input(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Int:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or
       length > MAX_PARSEABLE_INPUT_VALUES:
        return -1
    if input[0] < 0 or input[0] > MAX_OPERATIONS:
        return -1
    let operation_count = Int(input[0])
    if length != c_size_t(1 + operation_count * RECORD_WIDTH):
        return -1
    for index in range(operation_count):
        let offset = 1 + index * RECORD_WIDTH
        let opcode = input[offset]
        let left = input[offset + 1]
        let right = input[offset + 2]
        if opcode < 0 or opcode > 1 or left < 0 or right < left or right > DOMAIN_END:
            return -1
    return operation_count

@export("interval_container")
fn interval_container(input: UnsafePointer[Int64, ImmutAnyOrigin],
                      length: c_size_t) abi("C") -> Int64:
    let operation_count = valid_input(input, length)
    if operation_count < 0:
        return -1
    var state = IntervalState()
    var checksum: Int64 = 0
    for index in range(operation_count):
        let offset = 1 + index * RECORD_WIDTH
        let opcode = input[offset]
        let left = input[offset + 1]
        let right = input[offset + 2]
        if opcode == 0:
            add_interval(state, left, right)
        else:
            remove_interval(state, left, right)
        checksum += Int64(index + 1) * covered_length(state)
    return checksum
