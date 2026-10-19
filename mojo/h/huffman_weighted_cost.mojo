from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("huffman_weighted_cost")
fn huffman_weighted_cost(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<7:return -1
    let count=a[0];if count<2 or count>26 or n!=c_size_t(1+2*count):return -1
    var ids=InlineArray[Bool,26](fill=false);var w=InlineArray[Int64,26](fill=0);var sum:Int64=0
    for i in range(Int(count)):
        let id=a[1+2*i];let f=a[2+2*i]
        if id<97 or id>122 or ids[Int(id-97)] or f<=0:return -1
        ids[Int(id-97)]=true;w[i]=f;sum+=f
        if sum>2147483647:return -1
    var cost:Int64=0;var active=Int(count)
    while active>1:
        var x=0;for i in range(1,active):if w[i]<w[x]:x=i
        let aweight=w[x];w[x]=w[active-1];active-=1
        var y=0;for i in range(1,active):if w[i]<w[y]:y=i
        let bweight=w[y];w[y]=w[active-1];active-=1
        let merged=aweight+bweight;cost+=merged;w[active]=merged;active+=1
    if cap<8 or o==UnsafePointer[UInt8,MutAnyOrigin]():return -2
    let u=bitcast[UInt64](cost);for b in range(8):o[b]=UInt8((u>>UInt(8*b))&255)
    return cost
