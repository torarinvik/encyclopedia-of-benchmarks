from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn reverse_permutation_visit(n: Int, mut permutation: List[Int], mut words: List[Int64]):
    for value in permutation: words.append(Int64(value))
    var reverse_point = n
    for i in range(n-1):
        if permutation[i] > permutation[i+1]:
            reverse_point = i+1
            break
    for child in range(1,reverse_point):
        let temp = permutation[child-1]
        permutation[child-1] = permutation[child]; permutation[child] = temp
        reverse_permutation_visit(n,permutation,words)
        let undo = permutation[child-1]
        permutation[child-1] = permutation[child]; permutation[child] = undo
    if reverse_point+2 <= n and permutation[reverse_point-1] < permutation[reverse_point+1]:
        let temp = permutation[reverse_point]
        permutation[reverse_point] = permutation[reverse_point+1]; permutation[reverse_point+1] = temp
        reverse_permutation_visit(n,permutation,words)
        let undo = permutation[reverse_point]
        permutation[reverse_point] = permutation[reverse_point+1]; permutation[reverse_point+1] = undo

@export("reverse_search_permutation_enumeration")
fn reverse_search_permutation_enumeration(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let nv = input[0]
    if nv < 1 or nv > 4: return -1
    let n = Int(nv)
    var count = 1
    for i in range(2,n+1): count *= i
    let bytes = 8*(1+n*count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var permutation = List[Int](capacity=n)
    for i in range(n): permutation.append(i+1)
    var words = List[Int64](capacity=1+n*count)
    words.append(Int64(count))
    reverse_permutation_visit(n,permutation,words)
    for i in range(len(words)):
        for j in range(8): output[8*i+j] = UInt8((words[i] >> (8*j)) & 255)
    return Int64(bytes)
