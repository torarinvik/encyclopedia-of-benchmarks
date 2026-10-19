from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAXN=1023
fn left_leaf_visit(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,node:Int64,left_child:Bool,seen:UnsafePointer[UInt8,MutAnyOrigin],visited:UnsafePointer[Int,MutAnyOrigin])->Int64:
    if node== -1:return 0
    if node<0 or node>=n:return -2000000000
    let i=Int(node)
    if seen[i]!=0:return -2000000000
    seen[i]=1;visited[0]+=1
    let value=v[i*3];let left=v[i*3+1];let right=v[i*3+2]
    if value< -1000 or value>1000 or left< -1 or left>=n or right< -1 or right>=n:return -2000000000
    if left== -1 and right== -1:return value if left_child else 0
    let a=left_leaf_visit(v,n,left,True,seen,visited)
    if a== -2000000000:return a
    let b=left_leaf_visit(v,n,right,False,seen,visited)
    if b== -2000000000:return b
    return a+b
@export("sum_of_left_leaves")
fn sum_of_left_leaves(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,root:Int64) abi("C")->Int64:
    if n>1023:return -1
    if n==0:return 0 if root== -1 else -1
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or root<0 or root>=n:return -1
    var seen=InlineArray[UInt8,MAXN](fill=0);var count=InlineArray[Int,1](fill=0)
    let result=left_leaf_visit(v,Int(n),root,False,seen.unsafe_ptr(),count.unsafe_ptr())
    if result== -2000000000 or count[0]!=Int(n):return -1
    return result
