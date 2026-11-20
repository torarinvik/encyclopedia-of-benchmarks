from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer


fn bucket_index(key: Int64, level: Int, split: Int) -> Int:
    let base = 1 << level
    var remainder = key % Int64(base)
    if remainder < 0:
        remainder += Int64(base)
    var index = Int(remainder)
    if index < split:
        remainder = key % Int64(base << 1)
        if remainder < 0:
            remainder += Int64(base << 1)
        index = Int(remainder)
    return index


@export("linear_hashing_trace")
fn linear_hashing_trace(values: UnsafePointer[Int64, ImmutAnyOrigin],
                        length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 128:
        return -1
    let operation_count = values[0]
    if operation_count < 0 or operation_count > 63 or length != c_size_t(1 + 2 * operation_count):
        return -1

    var heads = InlineArray[Int32, 32]()
    var keys = InlineArray[Int64, 63]()
    var links = InlineArray[Int32, 63]()
    for bucket in range(32):
        heads[bucket] = -1
    var level = 1
    var split = 0
    var live_count = 0
    var allocated = 0
    var result: Int64 = 0

    for operation in range(Int(operation_count)):
        let opcode = values[1 + 2 * operation]
        let key = values[2 + 2 * operation]
        if opcode < 0 or opcode > 2 or key < -1024 or key > 1023:
            return -1
        let bucket = bucket_index(key, level, split)
        var previous: Int32 = -1
        var node = heads[bucket]
        while node != -1 and keys[Int(node)] != key:
            previous = node
            node = links[Int(node)]
        let found = node != -1
        var succeeded: Int64 = 0

        if opcode == 0 and not found:
            node = Int32(allocated)
            allocated += 1
            keys[Int(node)] = key
            links[Int(node)] = heads[bucket]
            heads[bucket] = node
            live_count += 1
            succeeded = 1
            let base = 1 << level
            let bucket_count = base + split
            if bucket_count < 32 and live_count > 2 * bucket_count:
                let old_bucket = split
                let new_bucket = base + split
                var current = heads[old_bucket]
                heads[old_bucket] = -1
                while current != -1:
                    let following = links[Int(current)]
                    var remainder = keys[Int(current)] % Int64(base << 1)
                    if remainder < 0:
                        remainder += Int64(base << 1)
                    if Int(remainder) == new_bucket:
                        links[Int(current)] = heads[new_bucket]
                        heads[new_bucket] = current
                    else:
                        links[Int(current)] = heads[old_bucket]
                        heads[old_bucket] = current
                    current = following
                split += 1
                if split == base:
                    level += 1
                    split = 0
        elif opcode == 1 and found:
            if previous == -1:
                heads[bucket] = links[Int(node)]
            else:
                links[Int(previous)] = links[Int(node)]
            live_count -= 1
            succeeded = 1
        elif opcode == 2 and found:
            succeeded = 1
        result = (result << 1) | succeeded
    return result
