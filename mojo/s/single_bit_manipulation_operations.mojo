from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("single_bit_manipulation_operations")
fn single_bit_manipulation_operations(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=3:return -1
    let op=a[0];let x=a[1];let p=a[2]
    if x< -2147483648 or x>2147483647 or op<0 or op>5:return -1
    if op==5:
        if p != -1:return -1
        return x & (x-1)
    if p<0 or p>31:return -1
    if op==0:return x | (1<<p)
    if op==1:return x & ~(1<<p)
    if op==2:return x ^ (1<<p)
    if op==3:return 1 if ((x>>p)&1)!=0 else 0
    return (x>>p)&1
