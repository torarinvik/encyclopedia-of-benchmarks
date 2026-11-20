from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_OPERATIONS = 64
comptime MAX_PARSEABLE_LENGTH = 130
comptime COUNTER_COUNT = 67
comptime HASH_COUNT = 4

@export("counting_bloom_filter_operation_trace")
fn counting_bloom_filter_operation_trace(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH: return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > MAX_OPERATIONS: return -1
    let count = Int(raw_count)
    if length != c_size_t(1 + 2 * count): return -1

    for operation in range(count):
        let opcode = input[1 + 2 * operation]
        let key = input[2 + 2 * operation]
        if opcode < 0 or opcode > 2 or key < 0 or key > 65535: return -1

    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(count): return -2

    var counters = InlineArray[UInt8, COUNTER_COUNT](fill=0)
    for operation in range(count):
        let opcode = input[1 + 2 * operation]
        let key = Int(input[2 + 2 * operation])
        let base = (17 * key + 3) % COUNTER_COUNT
        let stride = 1 + ((5 * key + 3) % (COUNTER_COUNT - 1))

        if opcode == 0:
            for hash in range(HASH_COUNT):
                let position = (base + hash * stride) % COUNTER_COUNT
                counters[position] = counters[position] + UInt8(1)
            output[operation] = UInt8(1)
        elif opcode == 1:
            # The input contract guarantees that the deleted key is live.
            for hash in range(HASH_COUNT):
                let position = (base + hash * stride) % COUNTER_COUNT
                counters[position] = counters[position] - UInt8(1)
            output[operation] = UInt8(1)
        else:
            var present = True
            for hash in range(HASH_COUNT):
                let position = (base + hash * stride) % COUNTER_COUNT
                if counters[position] == UInt8(0): present = False
            output[operation] = UInt8(1 if present else 0)
    return Int64(count)
