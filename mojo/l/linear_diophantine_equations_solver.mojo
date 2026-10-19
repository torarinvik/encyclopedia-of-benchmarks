from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn dio_eg(a:Int64,b:Int64)->InlineArray[Int64,3]:
    if b==0:
        var r=InlineArray[Int64,3](fill=0);r[0]=a;r[1]=1;return r
    let sub=dio_eg(b,a%b);var r=InlineArray[Int64,3](fill=0);r[0]=sub[0];r[1]=sub[2];r[2]=sub[1]-(a/b)*sub[2];return r
fn dio_pack(x:Int64,y:Int64)->Int64:return (x+10000001)*20000003+(y+10000001)
@export("linear_diophantine_equations_solver")
fn linear_diophantine_equations_solver(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let a=v[0];let b=v[1];let c=v[2]
    if a < -1000 or a>1000 or b < -1000 or b>1000 or c < -10000 or c>10000:return -1
    if a==0 and b==0:return if c==0:-3 else:-2
    if a==0:return if c%b==0:dio_pack(0,c/b) else:-2
    if b==0:return if c%a==0:dio_pack(c/a,0) else:-2
    let z=dio_eg(a,b)
    if c%z[0]!=0:return -2
    return dio_pack(z[1]*(c/z[0]),z[2]*(c/z[0]))
