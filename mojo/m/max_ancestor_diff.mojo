from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
from std.math import abs

@export("max_ancestor_diff")
fn max_ancestor_diff(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64) abi("C")->Int64:
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or count==0 or count>1023 or root<0 or root>=Int64(count):return -1
    let n=Int(count);var seen=InlineArray[Bool,1023](fill=False);var parents=InlineArray[Int,1023](fill=0)
    for i in range(n):
        let value=nodes[3*i];let left=nodes[3*i+1];let right=nodes[3*i+2]
        if value< -100000 or value>100000 or left< -1 or right< -1 or left>=Int64(count) or right>=Int64(count):return -1
        if left>=0:parents[Int(left)]+=1
        if right>=0:parents[Int(right)]+=1
    for i in range(n):if (i==Int(root) and parents[i]!=0) or (i!=Int(root) and parents[i]!=1):return -1
    var stack=InlineArray[Int64,1023](fill=0);var mins=InlineArray[Int64,1023](fill=0);var maxs=InlineArray[Int64,1023](fill=0)
    var top=1;stack[0]=root;mins[Int(root)]=nodes[3*Int(root)];maxs[Int(root)]=mins[Int(root)];var best:Int64=0;var reached=0
    while top>0:
        top-=1;let u=Int(stack[top]);if seen[u]:return -1;seen[u]=True;reached+=1
        let value=nodes[3*u];let lo=mins[u];let hi=maxs[u]
        let d1=abs(value-lo);let d2=abs(value-hi);if d1>best:best=d1;if d2>best:best=d2
        let left=nodes[3*u+1];let right=nodes[3*u+2]
        for side in range(2):
            let child=left if side==0 else right
            if child>=0:
                let c=Int(child);stack[top]=child;top+=1
                mins[c]=value if value<lo else lo;maxs[c]=value if value>hi else hi
    return best if reached==n else -1
