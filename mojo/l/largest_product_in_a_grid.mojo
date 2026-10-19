from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("largest_product_in_a_grid")
fn largest_product_in_a_grid(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v==UnsafePointer[Int64, ImmutAnyOrigin]() or n<2 or n>3971: return -1
    let rows=v[0]; let cols=v[1]
    if rows<0 or rows>63 or cols<0 or cols>63 or n!=c_size_t(2+rows*cols): return -1
    for i in range(2,Int(n)):
        if v[i]<0 or v[i]>1000: return -1
    var rs=InlineArray[Int64,4](fill=0); rs[0]=0;rs[1]=1;rs[2]=1;rs[3]=1
    var cs=InlineArray[Int64,4](fill=0); cs[0]=1;cs[1]=0;cs[2]=1;cs[3]= -1
    var best:Int64=0
    for r in range(Int(rows)):
        for c in range(Int(cols)):
            for d in range(4):
                var prod:Int64=1
                for off in range(4):
                    let rr=r+off*Int(rs[d]);let cc=c+off*Int(cs[d])
                    if rr<0 or rr>=Int(rows) or cc<0 or cc>=Int(cols): prod=0;break
                    prod*=v[2+rr*Int(cols)+cc]
                if prod>best:best=prod
    return best
