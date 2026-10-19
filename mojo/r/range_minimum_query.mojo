from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn rmq_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x)
    for j in range(8):o[at+j]=UInt8((b>>(8*j))&255)
@export("range_minimum_query")
fn range_minimum_query(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<4:return -1
    if v[0]<1 or v[0]>64:return -1
    let count=Int(v[0]);let qpos=1+count
    if n<=c_size_t(qpos) or v[qpos]<1 or v[qpos]>64:return -1
    let q=Int(v[qpos]);if n!=c_size_t(qpos+1+2*q):return -1
    var a=InlineArray[Int64,64](fill=0)
    for i in range(count):if v[1+i]<-1000 or v[1+i]>1000:return -1;a[i]=v[1+i]
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(q*8):return -2
    var table=InlineArray[Int64,448](fill=0)
    for i in range(count):table[i]=Int64(i)
    for level in range(1,7):
        let width=1<<level;let half=width>>1
        if width<=count:
            for i in range(count-width+1):
                let ia=Int(table[(level-1)*64+i]);let ib=Int(table[(level-1)*64+i+half]);table[level*64+i]=Int64(if a[ia]<a[ib]:ia else:ib)
    for j in range(q):
        let left=v[qpos+1+2*j];let right=v[qpos+2+2*j];var answer:Int64= -9223372036854775807-1
        if left>=0 and right>left and right<=count:
            let len=Int(right-left);var level=0
            while (1<<(level+1))<=len:level+=1
            let width=1<<level;let ia=Int(table[level*64+Int(left)]);let ib=Int(table[level*64+Int(right)-width]);answer=min(a[ia],a[ib])
        rmq_put(o,j*8,answer)
    return Int64(q*8)
