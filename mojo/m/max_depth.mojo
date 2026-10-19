from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray

@export("max_depth")
fn max_depth(nodes:UnsafePointer[Int64,ImmutAnyOrigin],count:c_size_t,root:Int64) abi("C")->Int64:
    if count>1023:return -1
    if count==0:return 0 if root == -1 else -1
    if nodes==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=Int64(count):return -1
    let n=Int(count);var seen=InlineArray[Bool,1023](fill=False);var stack=InlineArray[Int64,2046](fill=0);var depths=InlineArray[Int64,1023](fill=0)
    var top=1;stack[0]=root;depths[Int(root)]=1;var reached=0;var best=0
    while top>0:
        top-=1;let node=stack[top];let ix=Int(node)
        if ix<0 or ix>=n or seen[ix]:return -1
        seen[ix]=True;reached+=1
        let left=nodes[3*ix+1];let right=nodes[3*ix+2]
        if left< -1 or right< -1 or left>=Int64(count) or right>=Int64(count):return -1
        if depths[ix]>best:best=Int(depths[ix])
        if left>=0:depths[Int(left)]=depths[ix]+1;stack[top]=left;top+=1
        if right>=0:depths[Int(right)]=depths[ix]+1;stack[top]=right;top+=1
    return Int64(best) if reached==n else -1
