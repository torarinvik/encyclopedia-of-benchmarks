from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("largest_square_area_in_matrix_bottom_up")
fn largest_square_area_in_matrix(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 66: return -2
    let rows=v[0]; let cols=v[1]
    if rows<1 or rows>8 or cols<1 or cols>8 or n!=c_size_t(2+rows*cols): return -2
    var dp=InlineArray[Int64,81](fill=0); var best:Int64=0
    for ri in range(Int(rows)):
        let i=Int(rows)-1-ri
        for cj in range(Int(cols)):
            let j=Int(cols)-1-cj; let z=2+i*Int(cols)+j; let cell=v[z]
            if cell!=0 and cell!=1: return -2
            if cell==1:
                let a=dp[(i+1)*9+j]; let b=dp[i*9+j+1]; let c=dp[(i+1)*9+j+1]
                let m=min(min(a,b),c)+1; dp[i*9+j]=m
                if m>best: best=m
    return best
