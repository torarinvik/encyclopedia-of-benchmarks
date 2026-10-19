from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ham_cycle_search(n:Int,graph:InlineArray[Int64,64],mut visited:InlineArray[Int64,8],current:Int,position:Int)->Bool:
    if position==n:return graph[current*8]!=0
    for next in range(n):
        if graph[current*8+next]!=0 and visited[next]==0:
            visited[next]=1
            if ham_cycle_search(n,graph,visited,next,position+1):return True
            visited[next]=0
    return False
@export("hamiltonian_cycle_exists")
fn hamiltonian_cycle_exists(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>58:return -1
    let nn=input[0];let mm=input[1]
    if nn<3 or nn>8 or mm<0 or mm>nn*(nn-1)//2 or length!=c_size_t(2+2*mm):return -1
    let n=Int(nn);var graph=InlineArray[Int64,64](fill=0)
    for i in range(Int(mm)):
        let u=input[2+2*i];let v=input[3+2*i]
        if u<0 or u>=nn or v<0 or v>=nn or u==v:return -1
        if graph[Int(u)*8+Int(v)]!=0:return -1
        graph[Int(u)*8+Int(v)]=1;graph[Int(v)*8+Int(u)]=1
    var visited=InlineArray[Int64,8](fill=0);visited[0]=1
    return 1 if ham_cycle_search(n,graph,visited,0,1) else 0
