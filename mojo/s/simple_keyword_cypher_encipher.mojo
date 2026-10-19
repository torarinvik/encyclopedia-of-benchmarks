from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("simple_keyword_cypher_encipher")
fn simple_keyword_cypher_encipher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>323:return -1
    let kl=a[0];let ml=a[1];if kl<0 or kl>64 or ml<0 or ml>256 or n!=c_size_t(2+kl+ml):return -1
    var used=InlineArray[Bool,26]();var key=InlineArray[Int32,26]();var kc=0
    for i in range(Int(kl)):let x=a[2+i];if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1;let c=Int(x-65 if x<91 else x-97);if not used[c]:used[c]=True;key[kc]=Int32(c);kc+=1
    var map=InlineArray[Int32,26]();var p=0
    for i in range(kc):map[p]=key[i];p+=1
    for i in range(26):if not used[i]:map[p]=Int32(i);p+=1
    for i in range(Int(ml)):if a[2+Int(kl)+i]<0 or a[2+Int(kl)+i]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(ml):return -2
    for i in range(Int(ml)):
        let x=a[2+Int(kl)+i];if x>=65 and x<=90:o[i]=UInt8(65+map[Int(x-65)])
        elif x>=97 and x<=122:o[i]=UInt8(97+map[Int(x-97)])
        else:o[i]=UInt8(x)
    return ml
