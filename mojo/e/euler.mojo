from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("euler")
fn euler(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>516:return -2
    let nn=input[0];let start=input[1];let end=input[2];let mm=input[3]
    if nn<1 or nn>32 or mm<0 or mm>256 or start<0 or start>=nn or end<0 or end>=nn or length!=c_size_t(4+2*mm):return -2
    let n=Int(nn);var degree=List[Int](length=n,fill=0);var edges=InlineArray[Int64,1024](fill=0)
    for i in range(Int(mm)):
        let u=input[4+2*i];let v=input[5+2*i]
        if u<0 or u>=nn or v<0 or v>=nn or u==v or edges[Int(u)*32+Int(v)]!=0:return -2
        edges[Int(u)*32+Int(v)]=1;edges[Int(v)*32+Int(u)]=1;degree[Int(u)]+=1;degree[Int(v)]+=1
    var valid=True
    for v in range(n):
        let is_odd=degree[v]%2==1
        if start==end:
            if is_odd:valid=False
        else:
            if (v==Int(start) or v==Int(end))!=is_odd:valid=False
    return 1 if valid else 0
