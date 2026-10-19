from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime IDS=44
fn findid(ids:InlineArray[Int64,44],count:Int,id:Int64)->Int:
    for i in range(count):if ids[i]==id:return i
    return -1
@export("unweighted_graph")
fn unweighted_graph(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>64:return -1
    let directed=v[0];let initial=v[1];let ops=v[2]
    if (directed!=0 and directed!=1) or initial<0 or initial>12 or ops<0 or ops>16 or n!=c_size_t(3+initial+3*ops):return -1
    var ids=InlineArray[Int64,44](fill=0);var declared=InlineArray[UInt8,44](fill=0);var adj=InlineArray[UInt8,1936](fill=0);var count=0
    for i in range(Int(initial)):
        let id=v[3+i]
        if id < -2147483648 or id > 2147483647 or findid(ids,count,id)>=0:return -1
        ids[count]=id;declared[count]=1;count+=1
    var result=InlineArray[Int64,81](fill=0);var used=0;let offset=3+Int(initial)
    for oi in range(Int(ops)):
        let at=offset+3*oi;let op=v[at];let a=v[at+1];let b=v[at+2]
        if a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647:return -1
        if op==0:
            if b!=0:return -1
            let old=findid(ids,count,a)
            if old>=0 and declared[old]!=0:return -1
            var slot=old
            if slot<0:
                if count>=IDS:return -1
                slot=count;ids[count]=a;count+=1
            declared[slot]=1
        elif op==1:
            let from=findid(ids,count,a)
            if from<0 or declared[from]==0:return -1
            var to=findid(ids,count,b)
            if directed==0 and (to<0 or declared[to]==0):return -1
            if to<0:
                if count>=IDS:return -1
                to=count;ids[count]=b;count+=1
            if adj[from*IDS+to]!=0:return -1
            adj[from*IDS+to]=1
            if directed==0:adj[to*IDS+from]=1
        elif op==2:
            if b!=0:return -1
            let node=findid(ids,count,a)
            if node<0 or declared[node]==0:return -1
            var neighbors=InlineArray[Int64,44](fill=0);var nc=0
            for j in range(count):if adj[node*IDS+j]!=0:neighbors[nc]=ids[j];nc+=1
            for i in range(nc):
                for j in range(i+1,nc):if neighbors[j]<neighbors[i]:let t=neighbors[i];neighbors[i]=neighbors[j];neighbors[j]=t
            if used+2+nc>81:return -1
            result[used]=a;result[used+1]=Int64(nc);used+=2
            for j in range(nc):result[used]=neighbors[j];used+=1
        else:return -1
    let bytes=used*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(used):
        for b in range(8):o[i*8+b]=UInt8((result[i]>>(b*8))&255)
    return Int64(bytes)
