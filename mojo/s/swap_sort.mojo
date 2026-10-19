from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn swap_order_less(keys:UnsafePointer[Int64,ImmutAnyOrigin],order:UnsafePointer[Int,MutAnyOrigin],a:Int,b:Int)->Bool:
    let x=order[a];let y=order[b]
    return keys[x]<keys[y] or (keys[x]==keys[y] and x<y)
fn swap_sift(keys:UnsafePointer[Int64,ImmutAnyOrigin],order:UnsafePointer[Int,MutAnyOrigin],length:Int,start:Int):
    var root=start
    while root<length/2:
        var child=root*2+1
        if child+1<length and swap_order_less(keys,order,child,child+1):child+=1
        if not swap_order_less(keys,order,root,child):break
        let temp=order[root];order[root]=order[child];order[child]=temp;root=child
@export("swap_sort")
fn swap_sort(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n>256 or (n>0 and v==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var order=InlineArray[Int,256](fill=0);var visited=InlineArray[UInt8,256](fill=0)
    for i in range(Int(n)):order[i]=i
    var start=Int(n)/2
    while start>0:start-=1;swap_sift(v,order.unsafe_ptr(),Int(n),start)
    var finish=Int(n)
    while finish>1:
        finish-=1;let temp=order[0];order[0]=order[finish];order[finish]=temp;swap_sift(v,order.unsafe_ptr(),finish,0)
    for i in range(1,Int(n)):if v[order[i-1]]==v[order[i]]:return -1
    var swaps=0
    for first in range(Int(n)):
        if visited[first]!=0:continue
        var node=first;var cycle=0
        while visited[node]==0:
            visited[node]=1;node=order[node];cycle+=1
        if cycle>0:swaps+=cycle-1
    return swaps
