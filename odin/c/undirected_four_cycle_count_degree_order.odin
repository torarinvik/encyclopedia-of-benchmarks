// Clean-room degree-oriented simple C4 counter; see package RIGHTS.md.
package undirected_four_cycle_count_degree_order

import "core:c"

@(export)
undirected_four_cycle_count_degree_order :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 131 do return -1
    n64 := input[0]
    m64 := input[1]
    if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 do return -1
    n := int(n64)
    m := int(m64)
    if int(length) != 2 + 2*m do return -1

    var neighbors: [16][16]int
    var degree: [16]int
    previous_u: i64 = -1
    previous_v: i64 = -1
    for edge:=0;edge<m;edge+=1 {
        u64:=input[2+2*edge]
        v64:=input[3+2*edge]
        if u64<0 || u64>=n64 || v64<0 || v64>=n64 || u64>=v64 do return -1
        if edge!=0 && (u64<previous_u || (u64==previous_u && v64<=previous_v)) do return -1
        previous_u=u64
        previous_v=v64
        u:=int(u64)
        v:=int(v64)
        neighbors[u][degree[u]]=v
        degree[u]+=1
        neighbors[v][degree[v]]=u
        degree[v]+=1
    }

    var order: [16]int
    var rank: [16]int
    for i:=0;i<n;i+=1 {order[i]=i}
    for i:=1;i<n;i+=1 {
        key:=order[i]
        j:=i
        for j>0 {
            prior:=order[j-1]
            if degree[prior]<degree[key] || (degree[prior]==degree[key] && prior<key) do break
            order[j]=prior
            j-=1
        }
        order[j]=key
    }
    for i:=0;i<n;i+=1 {rank[order[i]]=i}

    var count: [16]i64
    total:i64=0
    for position:=0;position<n;position+=1 {
        pivot:=order[position]
        for bi:=0;bi<degree[pivot];bi+=1 {
            middle:=neighbors[pivot][bi]
            if rank[middle]>=position do continue
            for ci:=0;ci<degree[middle];ci+=1 {
                opposite:=neighbors[middle][ci]
                if rank[opposite]<position {
                    total+=count[opposite]
                    count[opposite]+=1
                }
            }
        }
        for vertex:=0;vertex<n;vertex+=1 {count[vertex]=0}
    }
    return total
}
