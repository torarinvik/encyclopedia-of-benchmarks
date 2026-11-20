from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_OPERATIONS = 64
comptime MAX_LEVELS = 6
comptime MAX_PARSEABLE_LENGTH = 98

fn active_component_size(n:Int,adjacency:InlineArray[Int,1024],blocked:InlineArray[Int,32],inout subtree_size:InlineArray[Int,32],vertex:Int,parent:Int)->Int:
    var total=1
    for neighbor in range(n):
        if adjacency[vertex*n+neighbor]!=0 and neighbor!=parent and blocked[neighbor]==0:
            total+=active_component_size(n,adjacency,blocked,subtree_size,neighbor,vertex)
    subtree_size[vertex]=total
    return total

fn active_choose_centroid(n:Int,adjacency:InlineArray[Int,1024],blocked:InlineArray[Int,32],subtree_size:InlineArray[Int,32],vertex:Int,parent:Int,total:Int)->Int:
    for neighbor in range(n):
        if adjacency[vertex*n+neighbor]!=0 and neighbor!=parent and blocked[neighbor]==0 and subtree_size[neighbor]>total//2:
            return active_choose_centroid(n,adjacency,blocked,subtree_size,neighbor,vertex,total)
    return vertex

fn active_record_component(n:Int,level:Int,adjacency:InlineArray[Int,1024],blocked:InlineArray[Int,32],inout record_count:InlineArray[Int,32],inout record_centroid:InlineArray[Int,192],inout record_branch:InlineArray[Int,192],inout record_distance:InlineArray[Int,192],centroid:Int,vertex:Int,parent:Int,distance:Int,branch:Int):
    if level>=MAX_LEVELS:return
    let index=vertex*MAX_LEVELS+level
    record_centroid[index]=centroid
    record_branch[index]=n if vertex==centroid else branch
    record_distance[index]=distance
    record_count[vertex]=level+1
    for neighbor in range(n):
        if adjacency[vertex*n+neighbor]!=0 and neighbor!=parent and blocked[neighbor]==0:
            let next_branch=neighbor if vertex==centroid else branch
            active_record_component(n,level,adjacency,blocked,record_count,record_centroid,record_branch,record_distance,centroid,neighbor,vertex,distance+1,next_branch)

fn active_build_centroids(n:Int,level:Int,adjacency:InlineArray[Int,1024],inout blocked:InlineArray[Int,32],inout subtree_size:InlineArray[Int,32],inout record_count:InlineArray[Int,32],inout record_centroid:InlineArray[Int,192],inout record_branch:InlineArray[Int,192],inout record_distance:InlineArray[Int,192],entry:Int):
    if level>=MAX_LEVELS:return
    let total=active_component_size(n,adjacency,blocked,subtree_size,entry,-1)
    let centroid=active_choose_centroid(n,adjacency,blocked,subtree_size,entry,-1,total)
    active_record_component(n,level,adjacency,blocked,record_count,record_centroid,record_branch,record_distance,centroid,centroid,-1,0,n)
    blocked[centroid]=1
    for neighbor in range(n):
        if adjacency[centroid*n+neighbor]!=0 and blocked[neighbor]==0:
            active_build_centroids(n,level+1,adjacency,blocked,subtree_size,record_count,record_centroid,record_branch,record_distance,neighbor)

fn active_recompute_branch(n:Int,active:InlineArray[Int,32],record_count:InlineArray[Int,32],record_centroid:InlineArray[Int,192],record_branch:InlineArray[Int,192],record_distance:InlineArray[Int,192],inout best:InlineArray[Int,1056],centroid:Int,branch:Int):
    best[centroid*(n+1)+branch]= -1
    for vertex in range(n):
        if active[vertex]!=0:
            for record in range(record_count[vertex]):
                let index=vertex*MAX_LEVELS+record
                if record_centroid[index]==centroid and record_branch[index]==branch and record_distance[index]>best[centroid*(n+1)+branch]:
                    best[centroid*(n+1)+branch]=record_distance[index]

fn active_diameter(n:Int,best:InlineArray[Int,1056])->Int:
    var answer=0
    for centroid in range(n):
        var first= -1
        var second= -1
        for branch in range(n+1):
            let distance=best[centroid*(n+1)+branch]
            if distance>first:
                second=first;first=distance
            elif distance>second:second=distance
        if second>=0 and first+second>answer:answer=first+second
    return answer

@export("dynamic_centroid_active_set_diameter")
fn dynamic_centroid_active_set_diameter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>c_size_t(MAX_PARSEABLE_LENGTH):return -1
    let n_value=input[0];let q_value=input[1]
    if n_value<1 or n_value>Int64(MAX_N) or q_value<0 or q_value>Int64(MAX_OPERATIONS):return -1
    let n=Int(n_value);let q=Int(q_value)
    if length!=c_size_t(n+1+q):return -1

    var adjacency=InlineArray[Int,1024](fill=0)
    var blocked=InlineArray[Int,32](fill=0)
    var subtree_size=InlineArray[Int,32](fill=0)
    var record_count=InlineArray[Int,32](fill=0)
    var record_centroid=InlineArray[Int,192](fill=0)
    var record_branch=InlineArray[Int,192](fill=0)
    var record_distance=InlineArray[Int,192](fill=0)
    var best=InlineArray[Int,1056](fill=0)
    var active=InlineArray[Int,32](fill=0)

    for vertex in range(1,n):
        let parent_value=input[vertex+1]
        if parent_value<0 or parent_value>=Int64(vertex):return -1
        let parent=Int(parent_value)
        adjacency[parent*n+vertex]=1;adjacency[vertex*n+parent]=1
    for offset in range(q):
        let operation=input[n+1+offset]
        if operation!= -1 and (operation<0 or operation>=Int64(n)):return -1
    active_build_centroids(n,0,adjacency,blocked,subtree_size,record_count,record_centroid,record_branch,record_distance,0)
    for centroid in range(n):
        for branch in range(n+1):best[centroid*(n+1)+branch]= -1

    var checksum:Int64=0
    var query_number=0
    for offset in range(q):
        let operation=input[n+1+offset]
        if operation== -1:
            query_number+=1
            checksum+=Int64(query_number)*Int64(active_diameter(n,best)+1)
        else:
            let vertex=Int(operation)
            active[vertex]=1 if active[vertex]==0 else 0
            for record in range(record_count[vertex]):
                let index=vertex*MAX_LEVELS+record
                let centroid=record_centroid[index];let branch=record_branch[index]
                let distance=record_distance[index]
                if active[vertex]!=0:
                    if distance>best[centroid*(n+1)+branch]:best[centroid*(n+1)+branch]=distance
                elif best[centroid*(n+1)+branch]==distance:
                    active_recompute_branch(n,active,record_count,record_centroid,record_branch,record_distance,best,centroid,branch)
    return checksum
