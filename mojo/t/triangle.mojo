from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import hypot
@export("triangle")
fn triangle(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=6:return -1
    for i in range(6):if a[i]< -100 or a[i]>100:return -1
    let x1=Float64(a[0]);let y1=Float64(a[1]);let x2=Float64(a[2]);let y2=Float64(a[3]);let x3=Float64(a[4]);let y3=Float64(a[5])
    if x1==x2 or x1==x3 or x2==x3 or y3==y1 or y3==y2:return -1
    let det=x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
    if det==0.0:return -1
    let s1=x1*x1+y1*y1;let s2=x2*x2+y2*y2;let s3=x3*x3+y3*y3
    let cx=(s1*(y2-y3)+s2*(y3-y1)+s3*(y1-y2))/(2.0*det)
    let cy= -(s1*(x2-x3)+s2*(x3-x1)+s3*(x1-x2))/(2.0*det)
    let sa=hypot(x2-x3,y2-y3);let sb=hypot(x1-x3,y1-y3);let sc=hypot(x1-x2,y1-y2);let peri=sa+sb+sc
    let ix=(sa*x1+sb*x2+sc*x3)/peri;let iy=(sa*y1+sb*y2+sc*y3)/peri
    let im1= -(x3-x1)/(y3-y1);let im2= -(x3-x2)/(y3-y2);let rhs1=im2*x1-y1;let rhs2=im1*x2-y2;let sd=im1-im2
    if sd==0.0:return -1
    let ox=(-rhs1+rhs2)/sd;let oy=(im2*rhs2-im1*rhs1)/sd
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<48:return -2
    var vals=InlineArray[Float64,6](cx,cy,ix,iy,ox,oy)
    for i in range(6):
        let bits=bitcast[UInt64](vals[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return 48
