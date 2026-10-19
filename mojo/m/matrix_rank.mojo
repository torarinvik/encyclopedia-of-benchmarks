from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
from std.math import abs

@export("matrix_rank")
fn matrix_rank(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 66: return -1
    let rows = Int(v[0]); let cols = Int(v[1])
    if rows < 1 or rows > 8 or cols < 1 or cols > 8 or n != c_size_t(2+rows*cols): return -1
    var a = InlineArray[Float64,64](fill=0.0); var marked = InlineArray[Bool,8](fill=False)
    for i in range(rows*cols):
        if v[i+2] != 0 and v[i+2] != 1: return -1
        a[i] = Float64(v[i+2])
    var rank = 0
    for col in range(cols):
        var pivot = rows
        for row in range(rows):
            if not marked[row] and abs(a[row*cols+col]) >= 1.0e-10: pivot = row; break
        if pivot == rows: continue
        rank += 1; marked[pivot] = True
        let pivot_value = a[pivot*cols+col]
        for c in range(col+1,cols): a[pivot*cols+c] /= pivot_value
        for row in range(rows):
            if row == pivot: continue
            let factor = a[row*cols+col]
            if abs(factor) >= 1.0e-10:
                for c in range(col+1,cols): a[row*cols+c] -= a[pivot*cols+c]*factor
    return Int64(rank)
