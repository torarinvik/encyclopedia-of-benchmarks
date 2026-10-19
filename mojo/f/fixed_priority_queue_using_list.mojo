from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn fixed_store_i64(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for b in range(8): output[offset + b] = UInt8((bits >> (8 * b)) & UInt64(255))

@export("fixed_priority_queue_using_list")
fn fixed_priority_queue_using_list(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                   output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 769: return -1
    let op_count = input[0]
    if op_count < 0 or op_count > 256 or Int(length) != 1 + 3 * Int(op_count): return -1
    var buckets = InlineArray[Int32, 300](fill=0)
    var counts = InlineArray[Int32, 3](fill=0)
    var heads = InlineArray[Int32, 3](fill=0)
    var dequeued = InlineArray[Int64, 256](fill=0)
    var nd = 0
    for op in range(Int(op_count)):
        let pos = 1 + op * 3
        let opcode = input[pos]
        let priority = input[pos + 1]
        let data = input[pos + 2]
        if opcode == 0:
            if priority < -3 or priority > 2 or data < -2147483648 or data > 2147483647: return -1
            var bucket = Int(priority)
            if bucket < 0: bucket += 3
            if counts[bucket] >= 100: return -1
            let tail = (Int(heads[bucket]) + Int(counts[bucket])) % 100
            buckets[bucket * 100 + tail] = Int32(data)
            counts[bucket] += 1
        elif opcode == 1:
            if priority != 0 or data != 0: return -1
            var bucket = 0
            while bucket < 3 and counts[bucket] == 0: bucket += 1
            if bucket == 3: return -1
            dequeued[nd] = Int64(buckets[bucket * 100 + Int(heads[bucket])]); nd += 1
            heads[bucket] = Int32((Int(heads[bucket]) + 1) % 100)
            counts[bucket] -= 1
        else: return -1
    let bytes = nd * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(nd): fixed_store_i64(output, i * 8, dequeued[i])
    return Int64(bytes)
