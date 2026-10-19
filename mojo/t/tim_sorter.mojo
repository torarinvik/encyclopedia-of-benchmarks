from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn tsm_binary(inout keys:InlineArray[Int64,512],inout ids:InlineArray[Int64,512],start:Int,end:Int,first:Int):
    var f=first
    if f>=end or f<=start:f=start+1
    while f<end:
        let key=keys[f];let id=ids[f];var lo=start;var hi=f
        while lo<hi:
            let mid=(lo+hi)/2
            if key<keys[mid]:hi=mid
            else:lo=mid+1
        for j in range(f,lo,-1):keys[j]=keys[j-1];ids[j]=ids[j-1]
        keys[lo]=key;ids[lo]=id;f+=1
fn tsm_merge(inout keys:InlineArray[Int64,512],inout ids:InlineArray[Int64,512],inout bases:InlineArray[Int,512],inout lens:InlineArray[Int,512],inout stack:Int,index:Int):
    let ba=bases[index];let la=lens[index];let bb=bases[index+1];let lb=lens[index+1]
    lens[index]=la+lb
    if index==stack-3:bases[index+1]=bases[index+2];lens[index+1]=lens[index+2]
    stack-=1
    var tk=InlineArray[Int64,512]();var ti=InlineArray[Int64,512]()
    for j in range(la):tk[j]=keys[ba+j];ti[j]=ids[ba+j]
    var l=0;var r=bb;var dest=ba;let rend=bb+lb
    while l<la and r<rend:
        if tk[l]<=keys[r]:keys[dest]=tk[l];ids[dest]=ti[l];l+=1
        else:keys[dest]=keys[r];ids[dest]=ids[r];r+=1
        dest+=1
    while l<la:keys[dest]=tk[l];ids[dest]=ti[l];l+=1;dest+=1
fn tsm_collapse(inout keys:InlineArray[Int64,512],inout ids:InlineArray[Int64,512],inout bases:InlineArray[Int,512],inout lens:InlineArray[Int,512],inout stack:Int):
    while stack>1:
        var idx=stack-2
        if idx>0 and lens[idx-1]<=lens[idx]+lens[idx+1]:
            if lens[idx-1]<lens[idx+1]:idx-=1
            tsm_merge(keys,ids,bases,lens,stack,idx)
        elif lens[idx]<=lens[idx+1]:tsm_merge(keys,ids,bases,lens,stack,idx)
        else:break
fn tsm_force(inout keys:InlineArray[Int64,512],inout ids:InlineArray[Int64,512],inout bases:InlineArray[Int,512],inout lens:InlineArray[Int,512],inout stack:Int):
    while stack>1:
        var idx=stack-2
        if idx>0 and lens[idx-1]<lens[idx+1]:idx-=1
        tsm_merge(keys,ids,bases,lens,stack,idx)
@export("tim_sorter_benchmark")
fn tim_sorter_benchmark(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1026:return -1
    let count0=a[0]
    if count0<0 or count0>512 or n!=c_size_t(1+2*count0):return -1
    let count=Int(count0);var keys=InlineArray[Int64,512]();var ids=InlineArray[Int64,512]();var seen=InlineArray[Bool,512]()
    for i in range(count):
        let key=a[1+2*i];let id=a[2+2*i]
        if key< -1000 or key>1000 or id<0 or id>=count0 or seen[Int(id)]:return -1
        seen[Int(id)]=True;keys[i]=key;ids[i]=id
    if count<32:
        tsm_binary(keys,ids,0,count,0)
    else:
        var rem=count;var r=0
        while rem>=32:r=r|(rem&1);rem=rem>>1
        let minrun=rem+r
        var bases=InlineArray[Int,512]();var lens=InlineArray[Int,512]();var stack=0;var start=0
        while start<count:
            var hi=start+1
            if hi<count:
                if keys[hi]<keys[start]:
                    hi+=1
                    while hi<count and keys[hi]<keys[hi-1]:hi+=1
                    var x=start;var y=hi-1
                    while x<y:
                        let k=keys[x];keys[x]=keys[y];keys[y]=k;let id=ids[x];ids[x]=ids[y];ids[y]=id;x+=1;y-=1
                else:
                    hi+=1
                    while hi<count and keys[hi]>=keys[hi-1]:hi+=1
            var run=hi-start
            if run<minrun:
                let force=min(minrun,count-start)
                tsm_binary(keys,ids,start,start+force,start+run);run=force
            bases[stack]=start;lens[stack]=run;stack+=1
            tsm_collapse(keys,ids,bases,lens,stack)
            start+=run
        tsm_force(keys,ids,bases,lens,stack)
    var checksum:Int64=0
    for i in range(count):
        let token=(keys[i]+1000)*513+ids[i]+1
        checksum=(checksum*1000003+token)%1000000007
    return checksum
