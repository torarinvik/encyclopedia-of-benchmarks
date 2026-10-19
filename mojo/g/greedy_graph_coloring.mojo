from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray
@export("greedy_graph_coloring")
fn greedy_graph_coloring(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>15 or v[0]<0 or v[0]>14 or n!=c_size_t(v[0]+1):return -1
    let count=Int(v[0]);let limit=(1<<count)-1;var adj=InlineArray[Int64,14](fill=0);var degree=InlineArray[Int,14](fill=0);var order=InlineArray[Int,14](fill=0);var colors=InlineArray[Int,14](fill=0)
    for i in range(count):
        let mask=v[1+i];if mask<0 or mask>limit or (mask&(Int64(1)<<i))!=0:return -1
        adj[i]=mask;order[i]=i;var rem=Int(mask)
        while rem!=0:rem&=rem-1;degree[i]+=1
    for i in range(count):
        for j in range(count):if ((adj[i]>>j)&1)!=((adj[j]>>i)&1):return -1
    for i in range(1,count):
        let current=order[i];var pos=i
        while pos>0 and degree[order[pos-1]]<degree[current]:order[pos]=order[pos-1];pos-=1
        order[pos]=current
    var color_count=0
    for p in range(count):
        let vertex=order[p];var used=InlineArray[Bool,15](fill=False)
        for other in range(count):if (adj[vertex]&(Int64(1)<<other))!=0 and colors[other]!=0:used[colors[other]]=True
        var color=1
        while used[color]:color+=1
        colors[vertex]=color
        if color>color_count:color_count=color
    var packed=UInt64(color_count)
    for i in range(count):packed|=UInt64(colors[i])<<UInt64(4*(i+1))
    return bitcast[Int64](packed)
