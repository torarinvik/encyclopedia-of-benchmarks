from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("spigotpi")
fn spigotpi(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=1 or v[0]<0 or v[0]>256:return -1
    let digits=Int(v[0])
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(digits):return -2
    if digits==0:return 0
    let boxes=digits*10/3;var rem=InlineArray[Int64,854](fill=0);var out=InlineArray[UInt8,256](fill=0)
    for i in range(boxes):rem[i]=2
    var held=0
    for i in range(digits):
        var carry:Int64=0;var sum:Int64=0;var cursor=boxes
        while cursor>0:
            cursor-=1;rem[cursor]*=10;sum=rem[cursor]+carry;let den=2*cursor+1;let q=sum/den;rem[cursor]=sum%den;carry=q*cursor
        rem[0]=sum%10;var q=sum/10
        if q==9:held+=1
        elif q==10:
            q=0
            for off in range(1,held+1):
                let pos=i-off;let d=out[pos]
                out[pos]=if d==57 then 48 else d+1
            held=1
        else:held=1
        out[i]=UInt8(48+q)
    for i in range(digits):o[i]=out[i]
    return Int64(digits)
