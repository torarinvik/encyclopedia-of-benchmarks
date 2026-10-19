from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mo_put(out:UnsafePointer[UInt8,MutAnyOrigin],p:Int,x:Int32):
    let u=UInt32(x)
    for b in range(4):out[p+b]=UInt8((u>>(8*b))&255)
@export("mo")
fn mo(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n<2 or n>195 or v[0]<1 or v[0]>64:return -1
    let count=Int(v[0]);let qo=1+count
    if Int(n)<=qo or v[qo]<0 or v[qo]>64 or Int(n)!=qo+1+2*Int(v[qo]):return -1
    let qcount=Int(v[qo]);var data=InlineArray[Int32,64](fill=0);var ql=InlineArray[Int64,64](fill=0);var qr=InlineArray[Int64,64](fill=0);var qi=InlineArray[Int64,64](fill=0);var ans=InlineArray[Int32,64](fill=0)
    for i in range(count):
        if v[1+i]<0 or v[1+i]>255:return -1
        data[i]=v[1+i]
    for i in range(qcount):
        let l=v[qo+1+2*i];let r=v[qo+2+2*i]
        if l<1 or r<l or r>count:return -1
        ql[i]=Int64(l-1);qr[i]=Int64(r-1);qi[i]=Int64(i)
    let bytes=qcount*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var block=1
    while block*block<count:block+=1
    for i in range(1,qcount):
        let l=ql[i];let r=qr[i];let ix=qi[i];var j=i
        while j>0:
            let prev=Int(qi[j-1]);let pb=Int(ql[j-1])/block;let cb=Int(l)/block
            if pb<cb or (pb==cb and qr[j-1]<=r):break
            ql[j]=ql[j-1];qr[j]=qr[j-1];qi[j]=qi[j-1];j-=1
        ql[j]=l;qr[j]=r;qi[j]=ix
    var freq=InlineArray[Int64,256](fill=0);var distinct=0;var left=0;var right=0
    for k in range(qcount):
        let tl=Int(ql[k]);let tr=Int(qr[k])
        while left<tl:let x=Int(data[left]);left+=1;freq[x]-=1;if freq[x]==0:distinct-=1
        while left>tl:left-=1;let x=Int(data[left]);freq[x]+=1;if freq[x]==1:distinct+=1
        while right<=tr:let x=Int(data[right]);right+=1;freq[x]+=1;if freq[x]==1:distinct+=1
        while right>tr+1:right-=1;let x=Int(data[right]);freq[x]-=1;if freq[x]==0:distinct-=1
        ans[Int(qi[k])]=Int32(distinct)
    for i in range(qcount):mo_put(out,4*i,ans[i])
    return Int64(bytes)
