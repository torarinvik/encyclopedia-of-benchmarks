from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn fold_ascii(x:Int64)->Int:
    let v=Int(x)
    return v+32 if v>=65 and v<=90 else v
@export("z_algorithm_search")
fn z_algorithm_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4096:return -1
    let tl=v[0];let pl=v[1]
    if tl<0 or tl>2047 or pl<0 or pl>2047 or n!=c_size_t(2+tl+pl):return -1
    for i in range(2,Int(n)):if v[i]<0 or v[i]>127:return -1
    if pl==0:
        let count=Int(tl)+1;let bytes=count*4
        if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
        for i in range(count):
            let x=UInt32(i+1)
            for b in range(4):o[4*i+b]=UInt8((x>>(8*b))&255)
        return Int64(count)
    let total=Int(tl+pl+1)
    var seq=InlineArray[Int,4095](fill=0);var z=InlineArray[Int,4095](fill=0)
    for i in range(Int(pl)):seq[i]=fold_ascii(v[2+Int(tl)+i])
    seq[Int(pl)]=256
    for i in range(Int(tl)):seq[Int(pl)+1+i]=fold_ascii(v[2+i])
    var left=0;var right=0
    for i in range(1,total):
        if i<right:z[i]=min(z[i-left],right-i)
        while i+z[i]<total and seq[z[i]]==seq[i+z[i]]:z[i]+=1
        if i+z[i]>right:left=i;right=i+z[i]
    var count=0
    for i in range(Int(pl)+1,total):if z[i]>=Int(pl):count+=1
    let bytes=count*4
    if (count>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()) or cap<c_size_t(bytes):return -2
    var outidx=0
    for i in range(Int(pl)+1,total):
        if z[i]>=Int(pl):
            let pos=UInt32(i-Int(pl))
            for b in range(4):o[4*outidx+b]=UInt8((pos>>(8*b))&255)
            outidx+=1
    return Int64(count)
