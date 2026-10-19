from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("kinematics")
fn kinematics(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=4:return -1
    let op=a[0];let x=a[1];let y=a[2];let z=a[3]
    if op<0 or op>3 or x< -1000 or x>1000 or y< -1000 or y>1000 or z< -1000 or z>1000:return -1
    if op==0:return 2*x+2*y*z
    if op==1:return 2*x*z+y*z*z
    if op==2:return 2*x*x+4*y*z
    return (x+y)*z
