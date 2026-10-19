from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("depth_first_search_iterative")
fn depth_first_search_iterative(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>518:return -1
    let n=input[0];let m=input[1];let source=input[2];let target=input[3]
    if n<1 or n>64 or m<0 or m>256 or source<0 or source>=n or length!=c_size_t(4+2*m):return -1
    for e in range(Int(m)):
        if input[4+2*e]<0 or input[4+2*e]>=n or input[5+2*e]<0 or input[5+2*e]>=n:return -1
    var visited=List[Int](length=Int(n),fill=0);var stack=List[Int](capacity=64);stack.append(Int(source));visited[Int(source)]=1
    while len(stack)>0:
        let u=stack[len(stack)-1];stack.pop()
        if Int64(u)==target:return 1
        for e in range(Int(m)):
            let l=input[4+2*e];let r=input[5+2*e];var neighbor:Int= -1
            if l==Int64(u):neighbor=Int(r)
            elif r==Int64(u):neighbor=Int(l)
            if neighbor>=0 and visited[neighbor]==0:visited[neighbor]=1;stack.append(neighbor)
    return 0
