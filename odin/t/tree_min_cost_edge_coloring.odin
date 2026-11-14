// Uncompiled matching-sensitivity tree edge-coloring draft.
package tree_min_cost_edge_coloring
import "core:c"

tec_assignment :: proc(d, width: int, cost: ^[256]i64, deletion: ^[16]i64) -> i64 {
    inf :: i64(1000000000000000)
    row_dual: [17]i64 = {}
    col_dual: [17]i64 = {}
    owner: [17]int = {}
    for row:=1; row<=d; row+=1 {
        previous: [17]int = {}
        used: [17]bool = {}
        slack: [17]i64
        for col:=0; col<=width; col+=1 { slack[col]=inf }
        owner[0]=row
        col:=0
        for {
            used[col]=true
            active:=owner[col]
            step:=inf
            next_col:=0
            for candidate:=1; candidate<=width; candidate+=1 {
                if used[candidate] do continue
                reduced:=cost[16*(active-1)+candidate-1]-row_dual[active]-col_dual[candidate]
                if reduced<slack[candidate] { slack[candidate]=reduced; previous[candidate]=col }
                if slack[candidate]<step { step=slack[candidate]; next_col=candidate }
            }
            if next_col==0 do return -1
            for candidate:=0; candidate<=width; candidate+=1 {
                if used[candidate] { row_dual[owner[candidate]]+=step; col_dual[candidate]-=step } else if candidate!=0 { slack[candidate]-=step }
            }
            col=next_col
            if owner[col]==0 do break
        }
        for col!=0 {
            parent:=previous[col]
            owner[col]=owner[parent]
            col=parent
        }
    }
    base:=i64(0)
    free_col:=-1
    for col:=0; col<width; col+=1 {
        if owner[col+1]!=0 { base+=cost[16*(owner[col+1]-1)+col] } else { free_col=col }
    }
    if width==d do return base
    if free_col<0 do return -1
    distance,updated: [16]i64
    for col:=0; col<width; col+=1 { distance[col]=inf }
    distance[free_col]=0
    for pass:=0; pass<d; pass+=1 {
        updated=distance
        for col:=0; col<width; col+=1 {
            row:=owner[col+1]-1
            if row<0 do continue
            for dest:=0; dest<width; dest+=1 {
                if distance[dest]!=inf {
                    value:=cost[16*row+dest]-cost[16*row+col]+distance[dest]
                    if value<updated[col] { updated[col]=value }
                }
            }
        }
        distance=updated
    }
    for col:=0; col<width; col+=1 {
        if distance[col]==inf do return -1
        deletion[col]=base+distance[col]
    }
    return base
}

@(export)
tree_min_cost_edge_coloring :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input==nil || length<2 || length>82 do return -1
    nv,kv:=input[0],input[1]
    if nv<1 || nv>64 || kv<1 || kv>16 do return -1
    n,k:=int(nv),int(kv)
    if length!=c.size_t(n+1+k) do return -1
    parents: [64]int = {}
    degree: [64]int = {}
    child_count: [64]int = {}
    for vertex:=1; vertex<n; vertex+=1 {
        raw:=input[1+vertex]
        if raw<0 || raw>=i64(vertex) do return -1
        parents[vertex]=int(raw)
        degree[int(raw)]+=1; degree[vertex]+=1
    }
    prices: [16]i64 = {}
    for color:=0; color<k; color+=1 {
        value:=input[n+1+color]
        if value<0 || value>1000000 do return -1
        prices[color]=value
    }
    for vertex:=0; vertex<n; vertex+=1 { if degree[vertex]>k do return -2 }
    for color:=1; color<k; color+=1 {
        value:=prices[color]; j:=color
        for j>0 && prices[j-1]>value { prices[j]=prices[j-1]; j-=1 }
        prices[j]=value
    }
    children: [1024]int = {}
    for vertex:=1; vertex<n; vertex+=1 {
        parent:=parents[vertex]
        children[16*parent+child_count[parent]]=vertex
        child_count[parent]+=1
    }
    tables: [1024]i64 = {}
    for vertex:=n-1; vertex>=0; vertex-=1 {
        d:=child_count[vertex]
        if d==0 do continue
        saturated:=vertex==0 && d==k
        width:=d+1
        if saturated { width=d }
        cost: [256]i64 = {}
        deletion: [16]i64 = {}
        for row:=0; row<d; row+=1 {
            child:=children[16*vertex+row]
            for col:=0; col<width; col+=1 {
                index:=min(col,child_count[child])
                cost[16*row+col]=prices[col]+tables[16*child+index]
            }
        }
        base:=tec_assignment(d,width,&cost,&deletion)
        if base<0 do return -1
        if saturated { tables[16*vertex]=base } else {
            for col:=0; col<width; col+=1 { tables[16*vertex+col]=deletion[col] }
        }
    }
    if child_count[0]==k do return tables[0]
    return tables[child_count[0]]
}
