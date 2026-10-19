from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn iddfs_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("iddfs")
fn iddfs(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
         output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<4 or length>101:return -1
    let start=input[0];let target=input[1];let maxdepth=input[2];let entries=input[3]
    if start<1 or start>16 or target<1 or target>16 or maxdepth<0 or maxdepth>8 or entries<0 or entries>16:return -1
    var adjacency=InlineArray[Int32,1024](fill=0);var degree=InlineArray[Int32,16](fill=0)
    var named=InlineArray[Bool,16](fill=False);var maxvertex=0;var total=0;var cursor=4
    for entry in range(Int(entries)):
        if cursor+2>Int(length):return -1
        let vertex=input[cursor];let deg=input[cursor+1];cursor+=2
        if vertex<1 or vertex>16 or deg<0 or deg>64:return -1
        let v=Int(vertex)
        if named[v-1] or deg>Int(length)-cursor or total+Int(deg)>64:return -1
        named[v-1]=True
        if v>maxvertex:maxvertex=v
        total+=Int(deg)
        for j in range(Int(deg)):
            let neighbor=input[cursor];cursor+=1
            if neighbor< -16 or neighbor>16:return -1
            if neighbor>maxvertex:maxvertex=Int(neighbor)
            if neighbor>=1:
                let offset=(v-1)*64+Int(degree[v-1])
                adjacency[offset]=Int32(neighbor);degree[v-1]+=1
    if cursor!=Int(length):return -1
    if maxvertex!=0 and (start>maxvertex or target>maxvertex):return -1
    var path=InlineArray[Int32,9](fill=0);var next=InlineArray[Int32,9](fill=0)
    var found=False;var founddepth=0;var pathlen=0
    if maxvertex!=0:
        var limit=0
        while limit<=Int(maxdepth) and not found:
            pathlen=1;path[0]=Int32(start);next[0]=0
            if start==target:found=True;founddepth=0;break
            while pathlen>0 and not found:
                let frame=pathlen-1;let current=Int(path[frame])
                if frame>=limit or next[frame]>=degree[current-1]:pathlen-=1;continue
                let neighbor=adjacency[(current-1)*64+Int(next[frame])]
                next[frame]+=1
                var prior=0
                while prior<pathlen and path[prior]!=neighbor:prior+=1
                if prior!=pathlen:continue
                path[pathlen]=neighbor;pathlen+=1
                if neighbor==target:found=True;founddepth=pathlen-1
                else:next[pathlen-1]=0
            limit+=1
    let outcount=3+(pathlen if found else 0);let bytes=outcount*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    iddfs_store(output,0,1 if found else 0);iddfs_store(output,8,Int64(founddepth) if found else -1);iddfs_store(output,16,Int64(pathlen) if found else 0)
    if found:
        for i in range(pathlen):iddfs_store(output,24+8*i,Int64(path[i]))
    return Int64(bytes)
