from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("mcoloring")
fn mcoloring(v:UnsafePointer[Int64,ImmutAnyOrigin],n_values:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n_values<2 or n_values>17:return -1
    let count=Int(v[0]);let limit=Int(v[1])
    if count<0 or count>14 or limit<1 or limit>14 or n_values!=c_size_t(count+2):return -1
    var masks=InlineArray[UInt32,14](fill=0);var parent=InlineArray[Int,14](fill=0)
    let valid=(1<<count)-1
    for i in range(count):
        if v[i+2]<0 or v[i+2]>valid:return -1
        masks[i]=UInt32(v[i+2]);if (masks[i] & (UInt32(1)<<UInt32(i)))!=0:return -1
        parent[i]=i
    for a in range(count):for b in range(a+1,count):
        let edge_a=(masks[a]&(UInt32(1)<<UInt32(b)))!=0;let edge_b=(masks[b]&(UInt32(1)<<UInt32(a)))!=0
        if edge_a!=edge_b:return -1
        if edge_a:
            var ra=a;while parent[ra]!=ra:ra=parent[ra]
            var rb=b;while parent[rb]!=rb:rb=parent[rb]
            if ra==rb:return -1
            parent[ra]=rb
    var colors=InlineArray[Int,14](fill=1);var visited=InlineArray[Bool,14](fill=False);var queue=InlineArray[Int,14](fill=0);var max_color=1
    for start in range(count):
        if visited[start]:continue
        var head=0;var tail=1;visited[start]=True;queue[0]=start
        while head<tail:
            let u=queue[head];head+=1
            for neighbor in range(count):
                if (masks[u]&(UInt32(1)<<UInt32(neighbor)))==0:continue
                if colors[u]==colors[neighbor]:colors[neighbor]+=1
                if colors[u]>max_color:max_color=colors[u]
                if colors[neighbor]>max_color:max_color=colors[neighbor]
                if max_color>limit:return 0
                if not visited[neighbor]:visited[neighbor]=True;queue[tail]=neighbor;tail+=1
    return 1
