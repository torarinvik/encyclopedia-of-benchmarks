from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("palindrome_with_stack")
fn palindrome_with_stack(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var stack=InlineArray[UInt8,128](fill=0)
    for i in range(count):let x=v[i+1];if x<0 or x>127:return -1;stack[i]=UInt8(x+ (32 if x>=65 and x<=90 else 0))
    for i in range(count):if stack[i]!=stack[count-1-i]:return 0
    return 1
