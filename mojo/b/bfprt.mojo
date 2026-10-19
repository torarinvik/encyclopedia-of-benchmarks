from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime INVALID = -2_147_483_649

fn insertion_sort(mut a: List[Int64], left: Int, right: Int):
    for i in range(left + 1, right + 1):
        var j = i
        while j > left and a[j - 1] > a[j]:
            let v = a[j - 1]; a[j - 1] = a[j]; a[j] = v; j -= 1

fn select_bfprt(mut a: List[Int64], left_in: Int, right_in: Int, rank: Int) -> Int64:
    var left = left_in
    var right = right_in
    while left < right:
        let count = right - left + 1
        let groups = (count + 4) // 5
        for group in range(groups):
            let gl = left + group * 5
            let gr = min(right, gl + 4)
            insertion_sort(a, gl, gr)
            let median = gl + (gr - gl + 1) // 2
            let tmp = a[left + group]; a[left + group] = a[median]; a[median] = tmp
        var pivot: Int64 = 0
        if groups == 1:
            pivot = a[left]
        else:
            pivot = select_bfprt(a, left, left + groups - 1, left + groups // 2)
        var less = left
        var current = left
        var greater = right + 1
        while current < greater:
            if a[current] < pivot:
                let tmp = a[less]; a[less] = a[current]; a[current] = tmp
                less += 1; current += 1
            elif a[current] > pivot:
                greater -= 1
                let tmp = a[current]; a[current] = a[greater]; a[greater] = tmp
            else:
                current += 1
        if rank < less: right = less - 1
        elif rank >= greater: left = greater
        else: return a[rank]
    return a[left]

@export("bfprt")
fn bfprt(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1026: return INVALID
    let n = input[0]; let k = input[1]
    if n < 1 or n > 1024 or k < 1 or k > n or length != c_size_t(n + 2): return INVALID
    var values = List[Int64](capacity=Int(n))
    for i in range(Int(n)):
        let v = input[i + 2]
        if v < -2_147_483_648 or v > 2_147_483_647: return INVALID
        values.append(v)
    return select_bfprt(values, 0, Int(n) - 1, Int(k) - 1)
