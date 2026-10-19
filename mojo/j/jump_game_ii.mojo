from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import InlineArray
@export("jump_game_ii")
fn jump_game_ii(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1024:return -1
    let count=Int(n)
    for i in range(count):if v[i]<0 or v[i]>count:return -1
    if count==1:return 0
    var queue=InlineArray[Int,1024](fill=0);var dist=InlineArray[Int,1024](fill=0);var seen=InlineArray[Bool,1024](fill=False);var head=0;var tail=1;queue[0]=0;seen[0]=True
    while head<tail:
        let cell=queue[head];head+=1;let far=cell+Int(v[cell])
        if far>=count-1:return Int64(dist[cell]+1)
        for next in range(cell+1,far+1):
            if not seen[next]:seen[next]=True;dist[next]=dist[cell]+1;queue[tail]=next;tail+=1
    return -1
