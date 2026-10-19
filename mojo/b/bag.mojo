from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

comptime MAX_INSERTS = 128
comptime MAX_QUERIES = 64

fn append_i64_le(mut bytes: List[UInt8], value: Int64):
    var bits = value
    for _ in range(8):
        bytes.append(UInt8(bits & 255))
        bits >>= 8

@export("bag")
fn bag(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2:
        return -1
    let insert_value = input[0]
    if insert_value < 0 or insert_value > MAX_INSERTS:
        return -1
    let inserts = Int(insert_value)
    if length < c_size_t(inserts + 2):
        return -1
    let query_value = input[inserts + 1]
    if query_value < 0 or query_value > MAX_QUERIES:
        return -1
    let queries = Int(query_value)
    if length != c_size_t(inserts + queries + 2):
        return -1
    var distinct = List[Int64](capacity=MAX_INSERTS)
    for i in range(inserts):
        let value = input[i + 1]
        if value < -2147483648 or value > 2147483647:
            return -1
        var seen = False
        for j in range(len(distinct)):
            if distinct[j] == value:
                seen = True
        if not seen:
            distinct.append(value)
    for i in range(queries):
        let value = input[inserts + 2 + i]
        if value < -2147483648 or value > 2147483647:
            return -1
    let required = 8 * (queries + 2)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var staged = List[UInt8](capacity=required)
    append_i64_le(staged, insert_value)
    append_i64_le(staged, 1 if inserts == 0 else 0)
    for i in range(queries):
        let target = input[inserts + 2 + i]
        var contains = Int64(0)
        for j in range(len(distinct)):
            if distinct[j] == target:
                contains = 1
        append_i64_le(staged, contains)
    for i in range(required):
        output[i] = staged[i]
    return Int64(required)
