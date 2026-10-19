from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("pythagorean_triple")
fn pythagorean_triple(values:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if values==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    var a=values[0];var b=values[1];var c=values[2]
    if a< -32768 or a>32767 or b< -32768 or b>32767 or c< -32768 or c>32767:return -1
    if a<=0 or b<=0 or c<=0:return 0
    if a>b:let t=a;a=b;b=t
    if b>c:let t=b;b=c;c=t
    if a>b:let t=a;a=b;b=t
    return 1 if a*a+b*b==c*c else 0
