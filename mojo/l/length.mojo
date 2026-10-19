from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn put_length(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for i in range(8):out[at+i]=UInt8((b>>(8*i))&255)
@export("length")
fn length(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>259:return -1
    let plen=v[0]
    if plen<0 or plen>256 or n!=c_size_t(plen+2):return -1
    var bytes=InlineArray[UInt8,256](fill=UInt8(0))
    for i in range(Int(plen)+1):
        let x=v[i+1]
        if x<0 or x>255:return -1
        if i==Int(plen):
            if x!=0:return -1
        else:
            if x==0:return -1
            bytes[i]=UInt8(x)
    var i=0;var count:Int64=0
    while i<Int(plen):
        let lead=bytes[i]
        if lead>=1 and lead<=127:i+=1
        elif lead>=194 and lead<=223:
            if i+1>=Int(plen) or bytes[i+1]<128 or bytes[i+1]>191:return -1
            i+=2
        elif lead>=224 and lead<=239:
            if i+2>=Int(plen):return -1
            let second=bytes[i+1];let third=bytes[i+2]
            if second<128 or second>191 or third<128 or third>191 or (lead==224 and second<160) or (lead==237 and second>159):return -1
            i+=3
        else:return -1
        count+=1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<16:return -2
    put_length(out,0,plen);put_length(out,8,count);return 16
