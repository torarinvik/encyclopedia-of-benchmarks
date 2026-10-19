from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.math import sqrt
@export("dodecahedron")
fn dodecahedron(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Float64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=2:return -1.0e300
    let edge=input[0];let quantity=input[1]
    if edge<1 or edge>1000000 or (quantity!=0 and quantity!=1):return -1.0e300
    let root5=sqrt(5.0)
    if quantity==0:return 3.0*sqrt(25.0+10.0*root5)*Float64(edge*edge)
    return ((15.0+7.0*root5)/4.0)*Float64(edge*edge*edge)
