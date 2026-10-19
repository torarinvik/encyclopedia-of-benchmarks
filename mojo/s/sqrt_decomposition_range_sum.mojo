from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn block_size(n:Int)->Int:
    var b=1
    while (b+1)*(b+1)<=n:b+=1
    return b
@export("sqrt_decomposition_range_sum")
fn sqrt_decomposition_range_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>258:return -1
    let nv=v[0]
    if nv<1 or nv>64 or n<c_size_t(nv+2):return -1
    let count=Int(nv);let ocv=v[count+1]
    if ocv<0 or ocv>64 or n!=c_size_t(2+count+3*ocv):return -1
    var a=InlineArray[Int64,64](fill=0);var blocks=InlineArray[Int64,64](fill=0)
    for i in range(count):
        if v[1+i]< -1000 or v[1+i]>1000:return -1
        a[i]=v[1+i]
    let ops=Int(ocv);let os=count+2;var qcount=0
    for i in range(ops):
        let p=os+3*i;let kind=v[p];let x=v[p+1];let y=v[p+2]
        if kind==0:
            if x<0 or x>=y or y>nv:return -1
            qcount+=1
        elif kind==1:
            if x<0 or x>=nv or y< -1000 or y>1000:return -1
        else:return -1
    let need=qcount*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    let bs=block_size(count)
    for i in range(count):blocks[i/bs]+=a[i]
    var stage=InlineArray[Int64,64](fill=0);var outn=0
    for i in range(ops):
        let p=os+3*i;let kind=v[p];let x=Int(v[p+1]);let y=v[p+2]
        if kind==0:
            let first_next=((x/bs)+1)*bs;var sum=a[x]
            if first_next>Int(y):
                for j in range(x+1,Int(y)):sum+=a[j]
            else:
                for j in range(x+1,first_next):sum+=a[j]
                let endblock=Int(y)/bs
                for block in range(first_next/bs,endblock):sum+=blocks[block]
                for j in range(endblock*bs,Int(y)):sum+=a[j]
            stage[outn]=sum;outn+=1
        else:
            blocks[x/bs]=blocks[x/bs]-a[x]+y;a[x]=y
    for i in range(outn):let bits=bitcast[UInt64](stage[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(need)
