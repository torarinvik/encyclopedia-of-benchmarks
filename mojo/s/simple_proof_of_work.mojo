from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from sha256 import sha256
fn sp_dec(h:UnsafePointer[Int64,MutAnyOrigin],p0:Int,v0:Int64)->Int:
    var p=p0;var v=v0;var d=InlineArray[Int64,20]();var c=0
    while True:d[c]=v%10+48;c+=1;v/=10;if v==0:break
    while c>0:c-=1;h[p]=d[c];p+=1
    return p
@export("simple_proof_of_work")
fn simple_proof_of_work(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<5 or n>133:return -1
    let block=a[0];let diff=a[1];let maxn=a[2];let tl=a[3];let pl=a[4]
    if block<0 or diff<0 or diff>2 or maxn<0 or maxn>4096 or tl<0 or tl>64 or pl<0 or pl>64 or n!=c_size_t(5+tl+pl):return -1
    for i in range(Int(tl+pl)):if a[5+i]<0 or a[5+i]>127:return -1
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<72:return -2
    var header=InlineArray[Int64,151]();var digest=InlineArray[UInt8,32]();let hex=InlineArray[UInt8,16](48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102)
    for nonce in range(Int(maxn)+1):
        var p=sp_dec(header.unsafe_ptr(),0,block)
        for i in range(Int(tl+pl)):header[p]=a[5+i];p+=1
        p=sp_dec(header.unsafe_ptr(),p,nonce)
        if sha256(header.unsafe_ptr(),c_size_t(p),digest.unsafe_ptr(),32)!=32:return -1
        var good=True
        for j in range(Int(diff)):let b=digest[j/2];let v=if j%2==0 then b>>4 else b&15;if v!=0:good=False
        if good:
            for j in range(8):o[j]=UInt8((UInt64(nonce)>>UInt(8*j))&255)
            for j in range(32):o[8+2*j]=hex[Int(digest[j]>>4)];o[9+2*j]=hex[Int(digest[j]&15)]
            return 72
    return -3
