from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime RG_SCALE=9007199254740992
@export("random_graph_generator")
fn random_graph_generator(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>2020 or v[0]<0 or v[0]>64 or (v[1]!=0 and v[1]!=1) or v[2]< -RG_SCALE or v[2]>2*RG_SCALE:return -1
    let vertices=Int(v[0]);let directed=v[1];let prob=v[2];let pairs=if vertices<2:0 else:vertices*(vertices-1)//2;let draws=if prob>0 and prob<RG_SCALE:pairs else:0
    if n!=c_size_t(3+draws):return -1
    for i in range(draws):if v[3+i]<0 or v[3+i]>=RG_SCALE:return -1
    var staged=InlineArray[UInt8,4096](fill=UInt8(0))
    if prob>=RG_SCALE:
        for a in range(vertices):
            for b in range(vertices):if a!=b:staged[a*vertices+b]=1
    elif prob>0:
        var di=0
        for a in range(vertices):
            for b in range(a+1,vertices):
                if v[3+di]<prob:staged[a*vertices+b]=1;if directed==0:staged[b*vertices+a]=1
                di+=1
    let bytes=vertices*vertices
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(bytes):o[i]=staged[i]
    return Int64(bytes)
