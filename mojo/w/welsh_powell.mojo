from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("welsh_powell")
fn welsh_powell(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>1026:return -1
    let vertices=a[0];let edges=a[1]
    if vertices<0 or vertices>32 or edges<0 or edges>512 or n!=c_size_t(2+2*edges):return -1
    var graph=InlineArray[Bool,1024]();var degree=InlineArray[Int32,32]();var order=InlineArray[Int32,32]();var colors=InlineArray[Int32,32]()
    for i in range(Int(vertices)):colors[i]= -1
    for i in range(Int(edges)):
        let u=a[2+2*i];let v=a[3+2*i]
        if u<0 or u>=vertices or v<0 or v>=vertices or u==v:return -1
        graph[Int(u)*32+Int(v)]=True;graph[Int(v)*32+Int(u)]=True
    for u in range(Int(vertices)):
        order[u]=Int32(u)
        for v in range(Int(vertices)):if graph[u*32+v]:degree[u]+=1
    for i in range(1,Int(vertices)):
        let key=order[i];var j=i
        while j>0 and degree[Int(order[j-1])]<degree[Int(key)]:order[j]=order[j-1];j-=1
        order[j]=key
    var color=0
    while True:
        var added=false
        for oi in range(Int(vertices)):
            let v=Int(order[oi]);if colors[v]>=0:continue
            var can=true
            for u in range(Int(vertices)):if graph[v*32+u] and colors[u]>=0:can=false
            if can:colors[v]=Int32(color);added=true
        if not added:break
        color+=1
    let bytes=Int(vertices)*8
    if (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()) or cap<c_size_t(bytes):return -2
    for i in range(Int(vertices)):
        let bits=bitcast[UInt64](Int64(colors[i]));for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
