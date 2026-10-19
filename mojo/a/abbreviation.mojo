from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("abbreviation")
fn abbreviation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 258:
        return -1
    let source_len = values[0]
    let target_len = values[1]
    if source_len < 0 or source_len > 128 or target_len < 0 or target_len > 128:
        return -1
    if length != c_size_t(2 + source_len + target_len):
        return -1
    for i in range(source_len):
        let c = values[2 + i]
        if not ((c >= 65 and c <= 90) or (c >= 97 and c <= 122)):
            return -1
    for i in range(target_len):
        let c = values[2 + source_len + i]
        if c < 65 or c > 90:
            return -1
    var current = List[Bool](length=129, fill=False)
    var next = List[Bool](length=129, fill=False)
    current[0] = True
    for si in range(source_len):
        for ti in range(target_len + 1):
            next[ti] = False
        let source = values[2 + si]
        var upper = source
        if source >= 97:
            upper = source - 32
        for ti in range(target_len + 1):
            if not current[ti]:
                continue
            if source >= 97:
                next[ti] = True
            if ti < target_len and upper == values[2 + source_len + ti]:
                next[ti + 1] = True
        for ti in range(target_len + 1):
            current[ti] = next[ti]
    if current[target_len]:
        return 1
    return 0
