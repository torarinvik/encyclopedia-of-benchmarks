from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn path_sum_recur(v:UnsafePointer[Int64,ImmutAnyOrigin],node:Int,sum:Int64,target:Int64)->Bool:
    let base=2+3*node;let total=sum+v[base];let l=v[base+1];let r=v[base+2]
    if l==-1 and r==-1:return total==target
    return (l!=-1 and path_sum_recur(v,Int(l),total,target)) or (r!=-1 and path_sum_recur(v,Int(r),total,target))
@export("path_sum")
fn path_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or v[1]<0 or v[1]>63:return -1
    let count=Int(v[1]);if Int(n)!=2+3*count:return -1
    if count==0:return 0
    for i in range(count):
        let p=2+3*i;if v[p] < -2147483648 or v[p]>2147483647:return -1
        for e in range(1,3):if v[p+e]<-1 or v[p+e]>=count:return -1
    var seen=InlineArray[Int64,63](fill=0);var stack=InlineArray[Int64,63](fill=0);var top=1;var visited=0;stack[0]=0
    while top>0:
        top-=1;let node=Int(stack[top]);if seen[node]!=0:return -1;seen[node]=1;visited+=1;let p=2+3*node
        if v[p+1]!=-1:stack[top]=v[p+1];top+=1
        if v[p+2]!=-1:stack[top]=v[p+2];top+=1
    if visited!=count:return -1
    return 1 if path_sum_recur(v,0,0,v[0]) else 0
