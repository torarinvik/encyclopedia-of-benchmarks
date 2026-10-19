from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.math import sqrt
@export("shreedharacharya")
fn shreedharacharya(a:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Float64,ImmutAnyOrigin]() or n!=3:return -1
    let x=a[0];let b=a[1];let c=a[2];if x!=x or b!=b or c!=c or x<0.000001 or x>1000000 or b< -1000000 or b>1000000 or c< -1000000 or c>1000000:return -1
    let disc=b*b-4.0*x*c;var count=0
    if disc==0:count=1
    elif disc>0:count=2
    if o==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    if count==1:o[0]= -b/(2.0*x)
    elif count==2:let rt=sqrt(disc);let den=2.0*x;o[0]=(-b+rt)/den;o[1]=(-b-rt)/den
    return count
