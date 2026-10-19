from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("greedy_min_vertex_cover")
fn greedy_min_vertex_cover(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>17 or v[0]<1 or v[0]>16 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);let limit=(UInt64(1)<<UInt64(count))-1;var neighbors=InlineArray[UInt64,16](fill=0)
    for i in range(count):
        if v[i+1]<0 or UInt64(v[i+1])>limit:return -1
        let mask=UInt64(v[i+1]);if (mask&(UInt64(1)<<UInt64(i)))!=0:return -1;neighbors[i]=mask
    for i in range(count):
        for j in range(i+1,count):if ((neighbors[i]>>UInt64(j))&1)!=((neighbors[j]>>UInt64(i))&1):return -1
    var chosen=UInt64(0)
    while True:
        var best= -1;var best_degree=0
        for i in range(count):
            var bits=neighbors[i];var degree=0
            while bits!=0:bits&=bits-1;degree+=1
            if degree>best_degree:best=i;best_degree=degree
        if best<0:return Int64(chosen)
        let bit=UInt64(1)<<UInt64(best);chosen|=bit
        for i in range(count):neighbors[i]&= ~bit
        neighbors[best]=0
