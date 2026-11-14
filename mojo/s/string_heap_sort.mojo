# Independent bounded NBench-style heap sort; see package NBENCH-LICENSE.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn string_heap_sift(mut keys: List[UInt32], start: Int, end: Int):
    var root = start
    while root < end//2:
        var child = 2*root+1
        if child+1 < end and keys[child] < keys[child+1]: child += 1
        if keys[root] >= keys[child]: break
        let value = keys[root]
        keys[root] = keys[child]; keys[child] = value
        root = child

@export("string_heap_sort")
fn string_heap_sort(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 257: return -1
    let nv = input[0]
    if nv < 0 or nv > 64 or length != c_size_t(1+4*Int(nv)): return -1
    let n = Int(nv)
    var keys = List[UInt32](capacity=n)
    for i in range(n):
        var key = UInt32(0)
        for j in range(4):
            let byte = input[1+4*i+j]
            if byte < 0 or byte > 127: return -1
            key = (key << 8) | UInt32(byte)
        keys.append(key)
    for i in range(n//2): string_heap_sift(keys,n//2-1-i,n)
    for i in range(1,n):
        let end = n-i
        let temp = keys[0]; keys[0] = keys[end]; keys[end] = temp
        string_heap_sift(keys,0,end)
    let bytes = 4*n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(n):
        for j in range(4): output[4*i+j] = UInt8((keys[i] >> (24-8*j)) & 255)
    return Int64(bytes)
