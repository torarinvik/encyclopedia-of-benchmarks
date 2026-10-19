from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from sha256 import sha256
fn sb_put(o:UnsafePointer[UInt8,MutAnyOrigin],p:Int,v:Int64):
    let z=bitcast[UInt64](v);for b in range(8):o[p+b]=UInt8((z>>UInt(8*b))&255)
fn sb_dec(h:UnsafePointer[Int64,MutAnyOrigin],p0:Int,v0:Int64)->Int:
    var p=p0;var v=v0;var d=InlineArray[Int64,20]();var c=0
    while True:d[c]=v%10+48;c+=1;v/=10;if v==0:break
    while c>0:c-=1;h[p]=d[c];p+=1
    return p
@export("simple_blockchain")
fn simple_blockchain(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>465:return -1
    let diff=a[0];let count=a[1];if diff<1 or diff>2 or count<1 or count>8 or a[2]<0 or a[2]>2147483647:return -1
    var ts=InlineArray[Int64,8]();var dl=InlineArray[Int32,8]();var data=InlineArray[Int32,512]();ts[0]=a[2];dl[0]=13
    let genesis=InlineArray[Int32,13](71,101,110,101,115,105,115,32,66,108,111,99,107);for j in range(13):data[j]=genesis[j]
    var cur=3;var dataoff=13
    for i in range(1,Int(count)):
        if cur+2>Int(n):return -1
        ts[i]=a[cur];let l=a[cur+1];cur+=2;if ts[i]<0 or ts[i]>2147483647 or l<0 or l>64 or cur+Int(l)>Int(n):return -1
        dl[i]=Int32(l);for j in range(Int(l)):if a[cur+j]<0 or a[cur+j]>127:return -1;data[dataoff+j]=Int32(a[cur+j])
        cur+=Int(l);dataoff+=Int(l)
    if cur!=Int(n):return -1
    var hashes=InlineArray[UInt8,512]();var nonces=InlineArray[Int64,8]();var header=InlineArray[Int64,160]();var digest=InlineArray[UInt8,32]()
    for i in range(Int(count)):
        var plen=0;plen=sb_dec(header.unsafe_ptr(),plen,Int64(i));plen=sb_dec(header.unsafe_ptr(),plen,ts[i]);header[plen]=46;plen+=1;header[plen]=48;plen+=1
        var off=0;for k in range(i):off+=Int(dl[k])
        for j in range(Int(dl[i])):header[plen]=data[off+j];plen+=1
        if i==0:header[plen]=48;plen+=1
        else:for j in range(64):header[plen]=Int64(hashes[(i-1)*64+j]);plen+=1
        var mined=False
        for nonce in range(4096):
            let end=sb_dec(header.unsafe_ptr(),plen,Int64(nonce))
            if sha256(header.unsafe_ptr(),c_size_t(end),digest.unsafe_ptr(),32)!=32:return -1
            let hex=InlineArray[Int32,16](48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102)
            var ok=True
            for z in range(Int(diff)):let b=digest[z/2];let nib=if z%2==0 then (b>>4) else (b&15);if hex[Int(nib)]!=48:ok=False
            if ok:
                nonces[i]=nonce
                for j in range(32):hashes[i*64+2*j]=UInt8(hex[Int(digest[j]>>4)]);hashes[i*64+2*j+1]=UInt8(hex[Int(digest[j]&15)])
                mined=True;break
        if not mined:return -3
    let bytes=24+88*Int(count);if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var out=InlineArray[UInt8,728]();var p=0;sb_put(out.unsafe_ptr(),p,0);p+=8;sb_put(out.unsafe_ptr(),p,count);p+=8
    for i in range(Int(count)):
        sb_put(out.unsafe_ptr(),p,i);p+=8;sb_put(out.unsafe_ptr(),p,ts[i]);p+=8;sb_put(out.unsafe_ptr(),p,nonces[i]);p+=8
        for j in range(64):out[p]=hashes[i*64+j];p+=1
    sb_put(out.unsafe_ptr(),p,1);p+=8;for j in range(bytes):o[j]=out[j]
    return Int64(bytes)
