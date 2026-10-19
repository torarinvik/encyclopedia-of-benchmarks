from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn bitonic_merge(values: UnsafePointer[Int64, MutAnyOrigin], low: Int, count: Int, ascending: Bool) -> None:
    if count <= 1: return
    let half = count // 2
    for i in range(low, low + half):
        if (values[i] > values[i + half]) == ascending:
            let t = values[i]; values[i] = values[i + half]; values[i + half] = t
    bitonic_merge(values, low, half, ascending)
    bitonic_merge(values, low + half, half, ascending)

fn bitonic_make(values: UnsafePointer[Int64, MutAnyOrigin], low: Int, count: Int, ascending: Bool) -> None:
    if count <= 1: return
    let half = count // 2
    bitonic_make(values, low, half, True)
    bitonic_make(values, low + half, half, False)
    bitonic_merge(values, low, count, ascending)

@export("bitonic_sort")
fn bitonic_sort(values: UnsafePointer[Int64, MutAnyOrigin], length: c_size_t) abi("C") -> None:
    if length > 1024 or (length > 0 and values == UnsafePointer[Int64, MutAnyOrigin]()): return
    let n = Int(length)
    if n <= 1: return
    if (n & (n - 1)) != 0: return
    bitonic_make(values, 0, n, True)
