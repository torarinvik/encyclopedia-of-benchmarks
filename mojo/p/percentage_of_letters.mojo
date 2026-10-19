from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pol_lower(x:Int64)->Int64:return x+32 if x>=65 and x<=90 else x
@export("percentage_of_letters")
fn percentage_of_letters(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4097:return -1
    let target=pol_lower(v[0]);if target<97 or target>122:return -1
    var matches=0
    for i in range(1,Int(n)):if v[i]<0 or v[i]>127:return -1;if pol_lower(v[i])==target:matches+=1
    return Int64(100*matches/(Int(n)-1))
