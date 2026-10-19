from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("newtons_law_of_gravitation")
fn newtons_law_of_gravitation(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1.0e300
    let missing=a[0]
    if missing<0 or missing>3:return -1.0e300
    var v=InlineArray[Float64,4]();var p=1
    for i in range(4):
        if i!=Int(missing):
            let x=a[p];p+=1
            if x<1 or x>1000:return -1.0e300
            v[i]=Float64(x)
    let g=6.6743e-11
    if missing==0:return g*v[1]*v[2]/(v[3]*v[3])
    if missing==1:return v[0]*v[3]*v[3]/(g*v[2])
    if missing==2:return v[0]*v[3]*v[3]/(g*v[1])
    return sqrt(g*v[1]*v[2]/v[0])
