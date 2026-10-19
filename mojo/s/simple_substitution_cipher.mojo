from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("simple_substitution_cipher")
fn simple_substitution_cipher(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<28 or n>284:return -1
    let mode=a[0];let m=a[27];if (mode!=0 and mode!=1) or m<0 or m>256 or n!=c_size_t(28+m):return -1
    var seen=InlineArray[Bool,26]();var key=InlineArray[Int32,26]()
    for i in range(26):let x=a[i+1];if x<65 or x>90 or seen[Int(x-65)]:return -1;seen[Int(x-65)]=True;key[i]=Int32(x-65)
    for i in range(Int(m)):if a[28+i]<0 or a[28+i]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(m):return -2
    for i in range(Int(m)):
        let x=a[28+i];if x>=65 and x<=90:
            let c=Int(x-65);var j=0
            if mode==0:j=Int(key[c])
            else:while j<26 and key[j]!=c:j+=1
            o[i]=UInt8(65+j)
        elif x>=97 and x<=122:
            let c=Int(x-97);var j=0
            if mode==0:j=Int(key[c])
            else:while j<26 and key[j]!=c:j+=1
            o[i]=UInt8(97+j)
        else:o[i]=UInt8(x)
    return m
