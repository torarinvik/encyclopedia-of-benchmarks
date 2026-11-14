from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn splits_valid(input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int, n: Int, edges: Int) -> Bool:
    let universe = (1 << n) - 1
    var masks = InlineArray[Int, 13](fill=0)
    var internal = InlineArray[Int, 13](fill=0)
    var internal_count = 0
    for i in range(edges):
        let raw = input[offset + i]
        if raw <= 0 or raw >= Int64(universe) or (raw & 1) != 0: return False
        let mask = Int(raw)
        masks[i] = mask
        for j in range(i):
            if masks[j] == mask: return False
        var size = 0
        for bit in range(n): size += (mask >> bit) & 1
        if size == 1 or size == n - 1:
            if size == n - 1 and mask != (universe ^ 1): return False
        elif size >= 2 and size <= n - 2:
            internal[internal_count] = mask
            internal_count += 1
        else: return False
    if internal_count != n - 3: return False
    for leaf in range(1, n):
        var found = False
        for i in range(edges):
            if masks[i] == (1 << leaf): found = True
        if not found: return False
    var root_found = False
    for i in range(edges):
        if masks[i] == (universe ^ 1): root_found = True
    if not root_found: return False
    for i in range(internal_count):
        for j in range(i + 1, internal_count):
            let overlap = internal[i] & internal[j]
            if overlap != 0 and overlap != internal[i] and overlap != internal[j]: return False
    return True

@export("non_shared_edges")
fn non_shared_edges(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 27: return -1
    let count = input[0]
    if count < 3 or count > 8: return -1
    let n = Int(count)
    let edges = 2 * n - 3
    if length != c_size_t(1 + 2 * edges): return -1
    if not splits_valid(input, 1, n, edges) or not splits_valid(input, 1 + edges, n, edges): return -1
    var shared = 0
    for i in range(edges):
        for j in range(edges):
            if input[1 + i] == input[1 + edges + j]:
                shared += 1
                break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var bits = UInt64(edges - shared)
    for byte in range(8):
        output[byte] = UInt8(bits & 255)
        bits >>= 8
    return 8
