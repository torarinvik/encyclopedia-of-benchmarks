from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MaxOps = 64
alias MaxBuckets = 8
alias MaxWords = 132
alias MaxBytes = 520

def hh_before(keys: view[UInt8], ids: view[UInt8], a: Int, b: Int) -> Bool:
    keys[a] < keys[b] or (keys[a] == keys[b] and ids[a] < ids[b])

def hh_swap(keys: mutable view[UInt8], ids: mutable view[UInt8], a: Int, b: Int) -> None:
    let key = keys[a]
    let insertion = ids[a]
    keys[a] = keys[b]
    ids[a] = ids[b]
    keys[b] = key
    ids[b] = insertion

def hh_push(keys: mutable view[UInt8], ids: mutable view[UInt8], sizes: mutable view[UInt8],
            bucket: Int, key: UInt8, insertion: UInt8) -> None:
    let base = bucket * MaxOps
    var child = Int(sizes[bucket])
    sizes[bucket] = UInt8(child + 1)
    keys[base + child] = key
    ids[base + child] = insertion
    while child > 0:
        let parent = (child - 1) // 2
        if not hh_before(keys, ids, base + child, base + parent): break
        hh_swap(keys, ids, base + child, base + parent)
        child = parent

def hh_pop(keys: mutable view[UInt8], ids: mutable view[UInt8], sizes: mutable view[UInt8], bucket: Int) -> None:
    sizes[bucket] = UInt8(Int(sizes[bucket]) - 1)
    let last = Int(sizes[bucket])
    if last == 0: return
    let base = bucket * MaxOps
    keys[base] = keys[base + last]
    ids[base] = ids[base + last]
    var parent = 0
    while True:
        let left = parent * 2 + 1
        if left >= last: break
        var child = left
        let right = left + 1
        if right < last and hh_before(keys, ids, base + right, base + left): child = right
        if not hh_before(keys, ids, base + child, base + parent): break
        hh_swap(keys, ids, base + child, base + parent)
        parent = child

def hh_write(bytes: mutable view[UInt8], offset: Int, value: Int64) -> None:
    let bits = UInt64(value)
    for byte in range(8): bytes[offset + byte] = UInt8((bits >> (byte * 8)) & 255)

@export("hash_heap_priority_queue_trace")
fn hash_heap_priority_queue_trace(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(3) or length > c_size_t(MaxWords): return -1
    let universe_value = input[0]
    let bucket_value = input[1]
    let count_value = input[2]
    if universe_value < 1 or universe_value > 128 or bucket_value < 1 or bucket_value > 8 or
       bucket_value > universe_value or count_value < 0 or count_value > MaxOps: return -1
    let universe = Int(universe_value)
    let bucket_count = Int(bucket_value)
    let count = Int(count_value)
    if length != c_size_t(3 + 2 * count): return -1
    var ops = InlineArray[UInt8, MaxOps](fill=0)
    var args = InlineArray[UInt8, MaxOps](fill=0)
    for op in range(count):
        let opcode = input[3 + 2 * op]
        let argument = input[4 + 2 * op]
        if opcode == 0:
            if argument < 0 or argument >= universe_value: return -1
        elif opcode == 1 or opcode == 2:
            if argument != 0: return -1
        else: return -1
        ops[op] = UInt8(opcode)
        args[op] = UInt8(argument)

    var keys = InlineArray[UInt8, MaxBuckets * MaxOps](fill=0)
    var ids = InlineArray[UInt8, MaxBuckets * MaxOps](fill=0)
    var sizes = InlineArray[UInt8, MaxBuckets](fill=0)
    var words = InlineArray[Int64, MaxOps + 1](fill=0)
    words[0] = Int64(count)
    for op in range(count):
        if ops[op] == 0:
            let bucket = Int(args[op]) * bucket_count // universe
            hh_push(keys[0:MaxBuckets * MaxOps], ids[0:MaxBuckets * MaxOps], sizes[0:MaxBuckets], bucket, args[op], UInt8(op))
            words[op + 1] = -2
        else:
            var bucket = 0
            while bucket < bucket_count and sizes[bucket] == 0: bucket += 1
            if bucket == bucket_count:
                words[op + 1] = -1
            else:
                let base = bucket * MaxOps
                words[op + 1] = (Int64(ids[base]) << 8) | Int64(keys[base])
                if ops[op] == 2: hh_pop(keys[0:MaxBuckets * MaxOps], ids[0:MaxBuckets * MaxOps], sizes[0:MaxBuckets], bucket)

    let required = (count + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2
    var staged = InlineArray[UInt8, MaxBytes](fill=0)
    for index in range(count + 1): hh_write(staged[0:MaxBytes], index * 8, words[index])
    for byte in range(required): output[byte] = staged[byte]
    Int64(required)
