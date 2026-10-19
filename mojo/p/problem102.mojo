from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn p102_inside(x1:Int64,y1:Int64,x2:Int64,y2:Int64,x3:Int64,y3:Int64)->Int:
    let abx=x2-x1;let aby=y2-y1;let acx=x3-x1;let acy=y3-y1
    var den=acx*aby-acy*abx;var a=-(x1*aby-y1*abx);var b=x1*acy-y1*acx
    if den==0:return -1
    if den<0:den=-den;a=-a;b=-b
    return 1 if a>0 and b>0 and a+b<den else 0
@export("problem102")
fn problem102(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<6 or n>6000 or n%6!=0:return -1
    for i in range(Int(n)):if v[i]<-1000 or v[i]>1000:return -1
    var count=Int64(0)
    for i in range(0,Int(n),6):
        let inside=p102_inside(v[i],v[i+1],v[i+2],v[i+3],v[i+4],v[i+5])
        if inside<0:return -1
        count+=inside
    return count
