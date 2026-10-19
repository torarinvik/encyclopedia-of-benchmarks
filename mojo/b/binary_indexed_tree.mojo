from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime QUERY_OFFSET: Int64 = 131_072_000_001
comptime FINAL_OFFSET: Int64 = 512_000_001

fn lowbit(i: Int) -> Int: return i & (-i)
fn prefix(tree: List[Int64], count_in: Int) -> Int64:
    var count = count_in; var sum: Int64 = 0
    while count > 0: sum += tree[count]; count -= lowbit(count)
    return sum

@export("binary_indexed_tree")
fn binary_indexed_tree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1538: return -1
    let nv = input[0]; let ov = input[1]
    if nv < 2 or nv > 256 or (nv & (nv - 1)) != 0 or ov < 0 or ov > 512 or length != c_size_t(2 + 3 * ov): return -1
    let n = Int(nv); let operations = Int(ov)
    for op in range(operations):
        let code = input[2 + 3 * op]; let first = input[3 + 3 * op]; let second = input[4 + 3 * op]
        if code == 0:
            if first < 0 or first >= nv or second < -1_000_000 or second > 1_000_000: return -1
        elif code == 1:
            if first < 0 or second < first or second >= nv: return -1
        else: return -1
    var data = List[Int64](capacity=n); var tree = List[Int64](capacity=n + 2)
    for _ in range(n): data.append(0)
    for _ in range(n + 2): tree.append(0)
    var checksum: Int64 = 0
    for op in range(operations):
        let code = input[2 + 3 * op]; let first = Int(input[3 + 3 * op]); let second = input[4 + 3 * op]
        if code == 0:
            data[first] += second; var index = first + 1
            while index <= n + 1: tree[index] += second; index += lowbit(index)
        else:
            let value = prefix(tree, Int(second + 1)) - prefix(tree, first)
            checksum += Int64(op + 1) * (value + QUERY_OFFSET)
    for i in range(n): checksum += Int64(operations + i + 1) * (data[i] + FINAL_OFFSET)
    return checksum
