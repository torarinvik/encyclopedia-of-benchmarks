package mibench_network_dijkstra
import "core:c"

MAX_NODES :: 6
MAX_QUEUE_ITEMS :: 1024
NONE :: i64(9999)
Queue_Item :: struct {node:int, distance:i64, previous:int}

@(export)
mibench_network_dijkstra :: proc "c" (input:[^]i64, length:c.size_t)->i64 {
    if input==nil || length<3 do return -1
    node_value:=input[0]
    if node_value<1 || node_value>MAX_NODES do return -1
    nodes:=int(node_value)
    if length!=c.size_t(2+nodes*nodes) do return -1
    source_value:=input[1]
    if source_value<0 || source_value>=node_value do return -1
    for index in 0..<nodes*nodes {
        cost:=input[2+index]
        if cost!=NONE && (cost<0 || cost>31) do return -1
    }

    distance:[MAX_NODES]i64
    reachable:[MAX_NODES]bool
    queue:[MAX_QUEUE_ITEMS]Queue_Item
    for node in 0..<nodes do distance[node]=NONE
    source:=int(source_value)
    distance[source]=0
    reachable[source]=true
    head,tail:=0,0
    queue[tail]=Queue_Item{source,0,int(NONE)}
    tail+=1
    for head<tail {
        item:=queue[head]
        head+=1
        for destination in 0..<nodes {
            cost:=input[2+item.node*nodes+destination]
            if cost==NONE do continue
            candidate:=item.distance+cost
            if !reachable[destination] || distance[destination]>candidate {
                distance[destination]=candidate
                reachable[destination]=true
                if tail>=MAX_QUEUE_ITEMS do return -2
                queue[tail]=Queue_Item{destination,candidate,item.node}
                tail+=1
            }
        }
    }
    checksum:i64=0
    mask:u64=0
    for node in 0..<nodes {
        if reachable[node] {
            checksum+=i64(node+1)*distance[node]
            mask|=u64(1)<<u64(node)
        }
    }
    return checksum+i64(mask)
}
