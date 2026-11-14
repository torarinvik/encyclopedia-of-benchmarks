# Independent bounded Ispell hash profile; see the package license and notice.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("cbench_ispell_hash")
fn cbench_ispell_hash(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 65: return -1
    let table_size = values[0]
    if table_size < 1 or table_size > 2147483647: return -1
    var hash = UInt32(0)
    for i in range(1, Int(length)):
        var character = values[i]
        if character < 1 or character > 127: return -1
        if character >= 97 and character <= 122: character -= 32
        if i <= 4:
            hash = (hash << 8) | UInt32(character)
        else:
            hash = ((hash << 5) | (hash >> 27)) ^ UInt32(character)
    return Int64(UInt64(hash) % UInt64(table_size))
