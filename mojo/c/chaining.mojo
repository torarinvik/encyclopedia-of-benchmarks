from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("chaining")
fn chaining(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 260: return -1
    let bucket_count = input[0]
    let operation_count = input[1]
    if bucket_count < 1 or bucket_count > 127 or operation_count < 0 or operation_count > 128 or length != 2 + 2 * operation_count: return -1
    var heads = InlineArray[Int64, 127](-1)
    var keys = InlineArray[Int64, 128](0)
    var next = InlineArray[Int64, 128](-1)
    var inserted: Int64 = 0
    var query_count: Int64 = 0
    var result: UInt64 = 0
    for op_index in range(operation_count):
        let operation = input[2 + 2 * op_index]
        let key = input[3 + 2 * op_index]
        if (operation != 0 and operation != 1) or key < 0 or key > 2147483647: return -1
        let bucket = key % bucket_count
        if operation == 0:
            if inserted >= 128: return -1
            keys[inserted] = key
            next[inserted] = -1
            if heads[bucket] < 0: heads[bucket] = inserted
            else:
                var node = heads[bucket]
                while next[node] >= 0: node = next[node]
                next[node] = inserted
            inserted += 1
        else:
            if query_count >= 63: return -1
            var node = heads[bucket]
            while node >= 0 and keys[node] != key: node = next[node]
            if node >= 0: result |= UInt64(1) << query_count
            query_count += 1
    return Int64(result)
