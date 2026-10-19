from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("prefix_sum2_d")
fn prefix_sum2_d(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    let invalid=Int64(-9223372036854775808)
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7 or n>262:return invalid
    let rows=v[0];let cols=v[1]
    if rows<1 or rows>16 or cols<1 or cols>16 or n!=c_size_t(2+rows*cols+4):return invalid
    let r1=v[2+Int(rows*cols)];let c1=v[3+Int(rows*cols)];let r2=v[4+Int(rows*cols)];let c2=v[5+Int(rows*cols)]
    if r1<0 or c1<0 or r2<r1 or c2<c1 or r2>=rows or c2>=cols:return invalid
    var p=InlineArray[Int64,289](fill=0)
    for r in range(Int(rows)):
        for c in range(Int(cols)):
            let x=v[2+r*Int(cols)+c]
            if x< -1000 or x>1000:return invalid
            let width=Int(cols)+1
            p[(r+1)*width+c+1]=x+p[r*width+c+1]+p[(r+1)*width+c]-p[r*width+c]
    let w=Int(cols)+1;let a=Int(r1);let b=Int(c1);let c=Int(r2)+1;let d=Int(c2)+1
    return p[c*w+d]-p[a*w+d]-p[c*w+b]+p[a*w+b]
