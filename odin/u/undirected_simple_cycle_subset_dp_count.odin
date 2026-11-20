// Clean-room all-length simple-cycle subset DP; see package RIGHTS.md.
package undirected_simple_cycle_subset_dp_count

import "core:c"

MAX_N :: 14
MAX_M :: 91
MAX_STATES :: 1 << MAX_N

@(export)
undirected_simple_cycle_subset_dp_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 185 do return -1
    n64 := input[0]
    m64 := input[1]
    if n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > n64*(n64-1)/2 || m64 > MAX_M do return -1
    n := int(n64)
    m := int(m64)
    if int(length) != 2 + 2*m do return -1

    var adjacency: [MAX_N][MAX_N]bool
    var neighbors: [MAX_N][MAX_N]int
    var degree: [MAX_N]int
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
        adjacency[u][v]=true
        adjacency[v][u]=true
        neighbors[u][degree[u]]=v
        degree[u]+=1
        neighbors[v][degree[v]]=u
        degree[v]+=1
    }

    var dp: [MAX_STATES*MAX_N]i64
    state_count:=1<<n
    for start:=0;start<n;start+=1 {dp[(1<<start)*MAX_N+start]=1}
    oriented_cycles:i64=0
    for mask:=1;mask<state_count;mask+=1 {
        start:=0
        for (mask & (1<<start))==0 {start+=1}
        cardinality:=0
        for vertex:=0;vertex<n;vertex+=1 {if (mask & (1<<vertex))!=0 {cardinality+=1}}
        for endpoint:=0;endpoint<n;endpoint+=1 {
            if (mask & (1<<endpoint))==0 do continue
            ways:=dp[mask*MAX_N+endpoint]
            if ways==0 do continue
            if cardinality>=3 && adjacency[endpoint][start] {oriented_cycles+=ways}
            for i:=0;i<degree[endpoint];i+=1 {
                next:=neighbors[endpoint][i]
                if next>start && (mask & (1<<next))==0 {dp[(mask | (1<<next))*MAX_N+next]+=ways}
            }
        }
    }
    return oriented_cycles/2
}
