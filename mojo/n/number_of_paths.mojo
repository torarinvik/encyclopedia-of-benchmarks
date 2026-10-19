from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn np_dfs(v:Int,dest:Int,n:Int,matrix:InlineArray[Int64,100],mut visited:InlineArray[Bool,10])->Int64:
    if v==dest:return 1
    visited[v]=True;var total:Int64=0
    for j in range(n):
        if matrix[v*n+j]==1 and not visited[j]:total+=np_dfs(j,dest,n,matrix,visited)
    visited[v]=False
    return total
@export("number_of_paths")
fn number_of_paths(a:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>103:return -1
    let n=a[0];let src=a[1];let dst=a[2]
    if n<1 or n>10 or length!=c_size_t(3+n*n):return -1
    for i in range(Int(n*n)):if a[i+3]!=0 and a[i+3]!=1:return -1
    if src<0 or dst<0:return -1
    if src>=n or dst>=n:return 0
    if src==dst:return 1
    var matrix=InlineArray[Int64,100]();var visited=InlineArray[Bool,10](fill=False)
    for i in range(Int(n*n)):matrix[i]=a[i+3]
    return np_dfs(Int(src),Int(dst),Int(n),matrix,visited)
