from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("permutation_cipher")
fn permutation_cipher(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>74 or v[0]<0 or v[0]>64:return -1
    let len=Int(v[0]);let kp=len+1;if Int(n)<=kp or v[kp]<1 or v[kp]>8 or Int(n)!=kp+Int(v[kp])+1:return -1
    let width=Int(v[kp]);var key=InlineArray[Int64,8](fill=0);var seen=InlineArray[Int64,8](fill=0)
    for i in range(width):let x=v[kp+1+i];if x<1 or x>width or seen[Int(x-1)]!=0:return -1;seen[Int(x-1)]=1;key[i]=x
    var text=InlineArray[UInt8,128](fill=0);var used=0
    for i in range(len):
        let x=v[i+1];if x<0 or x>127:return -1
        if x==32 or (x>=9 and x<=13):continue
        text[used]=UInt8(x- (32 if x>=97 and x<=122 else 0));used+=1
    while used%width!=0:text[used]=88;used+=1
    var h:UInt64=0
    for b in range(0,used,width):for j in range(width):h=(h*257+UInt64(text[b+Int(key[j])-1]))%1000000007
    return Int64(h)
