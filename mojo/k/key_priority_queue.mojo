from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime M=32
fn kp_find(keys:InlineArray[Int64,M],n:Int,key:Int64)->Int:
    for i in range(n):if keys[i]==key:return i
    return n
fn kp_swap(mut keys:InlineArray[Int64,M],mut ps:InlineArray[Int64,M],i:Int,j:Int):
    let k=keys[i];keys[i]=keys[j];keys[j]=k;let p=ps[i];ps[i]=ps[j];ps[j]=p
fn kp_up(mut keys:InlineArray[Int64,M],mut ps:InlineArray[Int64,M],idx0:Int):
    var i=idx0
    while i>0:
        let par=(i-1)//2
        if ps[par]<=ps[i]:break
        kp_swap(keys,ps,par,i);i=par
fn kp_down(mut keys:InlineArray[Int64,M],mut ps:InlineArray[Int64,M],n:Int,idx0:Int):
    var i=idx0
    while 2*i+1<n:
        let l=2*i+1;let r=l+1
        if ps[l]<ps[i] and (r>=n or ps[l]<ps[r]):kp_swap(keys,ps,i,l);i=l
        elif r<n and ps[r]<ps[i]:kp_swap(keys,ps,i,r);i=r
        else:break
@export("key_priority_queue")
fn key_priority_queue(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>98 or a[0]<0 or a[0]>32:return -1
    var keys=InlineArray[Int64,M]();var ps=InlineArray[Int64,M]();var ans=InlineArray[Int64,M]();var sz=0;var outn=0;var pos=1
    for _ in range(Int(a[0])):
        if pos>=Int(n):return -1
        let op=a[pos]
        if op==0 or op==1:
            if pos+2>=Int(n):return -1
            let key=a[pos+1];let pri=a[pos+2]
            if key< -1000000000 or key>1000000000 or pri< -1000000000 or pri>1000000000:return -1
            pos+=3;let found=kp_find(keys,sz,key)
            if op==0 and found<sz:return -1
            if op==0 or found==sz:
                keys[sz]=key;ps[sz]=pri;kp_up(keys,ps,sz);sz+=1
            else:
                ps[found]=pri
                if found>0 and ps[(found-1)//2]>pri:kp_up(keys,ps,found)
                else:
                    let l=2*found+1;let r=l+1
                    if (l<sz and ps[l]<pri) or (r<sz and ps[r]<pri):kp_down(keys,ps,sz,found)
        elif op==2:
            pos+=1
            if sz==0:return -1
            kp_swap(keys,ps,0,sz-1);sz-=1;ans[outn]=keys[sz];outn+=1
            if sz>0:kp_down(keys,ps,sz,0)
        elif op==3:
            if pos+1>=Int(n):return -1
            let key=a[pos+1]
            if key< -1000000000 or key>1000000000:return -1
            pos+=2;ans[outn]=1 if kp_find(keys,sz,key)<sz else 0;outn+=1
        elif op==4:
            pos+=1;ans[outn]=1 if sz==0 else 0;outn+=1
        else:return -1
    if pos!=Int(n):return -1
    let bytes=outn*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(outn):
        let bits=UInt64(ans[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return bytes
