from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("kaprekar_numbers_in_range")
fn kaprekar_numbers_in_range(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2:return -1
    let lo=a[0];let hi=a[1]
    if lo<0 or lo>hi or hi>100000:return -1
    var required=0
    for x in range(Int(lo),Int(hi)+1):
        var good=x==0 or x==1;let sq=Int64(x)*Int64(x);var p:Int64=1;var v=Int64(x)
        while v>0:p*=10;v//=10
        if x>1:let r=sq%p;good=r!=0 and sq//p+r==x
        if good:
            var z=x;var digits=1
            while z>=10:z//=10;digits+=1
            required+=digits+1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    var pos=0
    for x in range(Int(lo),Int(hi)+1):
        var good=x==0 or x==1;let sq=Int64(x)*Int64(x);var p:Int64=1;var v=Int64(x)
        while v>0:p*=10;v//=10
        if x>1:let r=sq%p;good=r!=0 and sq//p+r==x
        if good:
            var digits=InlineArray[UInt8,20]();var cnt=0;var z=x
            if z==0:digits[0]=UInt8(48);cnt=1
            while z>0:digits[cnt]=UInt8(48+z%10);cnt+=1;z//=10
            while cnt>0:cnt-=1;o[pos]=digits[cnt];pos+=1
            o[pos]=0;pos+=1
    return pos
