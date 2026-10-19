from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("tournament_sort")
fn tournament_sort(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or a[0]<0 or a[0]>512 or n!=c_size_t(a[0]+1):return -1
    let count=Int(a[0]);var vals=InlineArray[Int64,512]()
    for i in range(count):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
        vals[i]=a[i+1]
    var leaves=1
    while leaves<count:leaves*=2
    var tree=InlineArray[Int,1025]()
    for i in range(2*leaves):tree[i]=-1
    for i in range(count):tree[leaves+i]=i
    for z in range(leaves-1):
        let node=leaves-1-z;let l=tree[node*2];let r=tree[node*2+1]
        tree[node]=if l<0:r elif r<0:l elif vals[l]<=vals[r]:l else:r
    let bytes=(1+count)*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var v=UInt64(count)
    for b in range(8):o[b]=UInt8((v>>(8*b))&255)
    for outi in range(count):
        let winner=tree[1];v=UInt64(vals[winner])
        for b in range(8):o[(1+outi)*8+b]=UInt8((v>>(8*b))&255)
        var node=leaves+winner;tree[node]= -1
        while node>1:
            node/=2;let l=tree[node*2];let r=tree[node*2+1]
            tree[node]=if l<0:r elif r<0:l elif vals[l]<=vals[r]:l else:r
    return Int64(bytes)
