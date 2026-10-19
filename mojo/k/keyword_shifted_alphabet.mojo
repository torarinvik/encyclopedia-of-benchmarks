from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("keyword_shifted_alphabet")
fn keyword_shifted_alphabet(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>542:return -1
    let op=a[0];let kn=a[1];let mn=a[2]
    if (op!=0 and op!=1) or kn<1 or kn>26 or mn<1 or mn>512 or n!=c_size_t(3+kn+mn):return -1
    var seen=InlineArray[Bool,26]();var key=InlineArray[Int64,26]()
    for i in range(Int(kn)):
        var c=a[3+i]
        if c>=65 and c<=90:c+=32
        if c<97 or c>122:return -1
        let j=Int(c-97)
        if seen[j]:return -1
        seen[j]=True;key[i]=c
    for i in range(Int(mn)):if a[3+Int(kn)+i]<0 or a[3+Int(kn)+i]>127:return -1
    var cipher=InlineArray[Int64,26]();var e=0
    for i in range(Int(kn)):cipher[e]=key[i];e+=1
    for i in range(26):if not seen[i]:cipher[e]=97+i;e+=1
    var map=InlineArray[Int64,26]()
    for i in range(26):map[Int(cipher[i]-97)]=97+i
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<mn:return -2
    for i in range(Int(mn)):
        let c=a[3+Int(kn)+i];var outc=c;var idx=-1;var upper=False
        if c>=65 and c<=90:idx=Int(c-65);upper=True
        elif c>=97 and c<=122:idx=Int(c-97)
        if idx>=0:
            let v=if op==0 then cipher[idx] else map[idx]
            outc=v-32 if upper else v
        o[i]=UInt8(outc)
    return mn
