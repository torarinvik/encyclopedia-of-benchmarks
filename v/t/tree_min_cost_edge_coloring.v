// Uncompiled matching-sensitivity tree edge-coloring draft.
fn tec_assignment(d int, width int, cost [256]i64, mut deletion [16]i64) i64 {
    inf := i64(1000000000000000)
    mut row_dual := [17]i64{}
    mut col_dual := [17]i64{}
    mut owner := [17]int{}
    for row in 1 .. d+1 {
        mut previous := [17]int{}
        mut used := [17]bool{}
        mut slack := [17]i64{}
        for col in 0 .. width+1 { slack[col]=inf }
        owner[0]=row
        mut col:=0
        for {
            used[col]=true
            active:=owner[col]
            mut step:=inf
            mut next_col:=0
            for candidate in 1 .. width+1 {
                if used[candidate] { continue }
                reduced:=cost[16*(active-1)+candidate-1]-row_dual[active]-col_dual[candidate]
                if reduced<slack[candidate] { slack[candidate]=reduced; previous[candidate]=col }
                if slack[candidate]<step { step=slack[candidate]; next_col=candidate }
            }
            if next_col==0 { return -1 }
            for candidate in 0 .. width+1 {
                if used[candidate] { row_dual[owner[candidate]]+=step; col_dual[candidate]-=step }
                else if candidate!=0 { slack[candidate]-=step }
            }
            col=next_col
            if owner[col]==0 { break }
        }
        for col!=0 {
            parent:=previous[col]
            owner[col]=owner[parent]
            col=parent
        }
    }
    mut base:=i64(0)
    mut free_col:=-1
    for col in 0 .. width {
        if owner[col+1]!=0 { base+=cost[16*(owner[col+1]-1)+col] } else { free_col=col }
    }
    if width==d { return base }
    if free_col<0 { return -1 }
    mut distance:=[16]i64{}
    for col in 0 .. width { distance[col]=inf }
    distance[free_col]=0
    for _ in 0 .. d {
        mut updated:=distance
        for col in 0 .. width {
            row:=owner[col+1]-1
            if row<0 { continue }
            for dest in 0 .. width {
                if distance[dest]!=inf {
                    value:=cost[16*row+dest]-cost[16*row+col]+distance[dest]
                    if value<updated[col] { updated[col]=value }
                }
            }
        }
        distance=updated
    }
    for col in 0 .. width {
        if distance[col]==inf { return -1 }
        deletion[col]=base+distance[col]
    }
    return base
}

@[export: 'tree_min_cost_edge_coloring']
pub fn tree_min_cost_edge_coloring(input &i64, length usize) i64 {
    if length<2 || length>82 { return -1 }
    unsafe {
        if input==nil { return -1 }
        nv,kv:=input[0],input[1]
        if nv<1 || nv>64 || kv<1 || kv>16 { return -1 }
        n,k:=int(nv),int(kv)
        if length!=usize(n+1+k) { return -1 }
        mut parents:=[64]int{}
        mut degree:=[64]int{}
        mut child_count:=[64]int{}
        for vertex in 1 .. n {
            raw:=input[1+vertex]
            if raw<0 || raw>=i64(vertex) { return -1 }
            parents[vertex]=int(raw)
            degree[int(raw)]++
            degree[vertex]++
        }
        mut prices:=[16]i64{}
        for color in 0 .. k {
            value:=input[n+1+color]
            if value<0 || value>1000000 { return -1 }
            prices[color]=value
        }
        for vertex in 0 .. n { if degree[vertex]>k { return -2 } }
        for color in 1 .. k {
            value:=prices[color]
            mut j:=color
            for j>0 && prices[j-1]>value { prices[j]=prices[j-1]; j-- }
            prices[j]=value
        }
        mut children:=[1024]int{}
        for vertex in 1 .. n {
            parent:=parents[vertex]
            children[16*parent+child_count[parent]]=vertex
            child_count[parent]++
        }
        mut tables:=[1024]i64{}
        mut vertex:=n-1
        for vertex>=0 {
            d:=child_count[vertex]
            if d!=0 {
                saturated:=vertex==0 && d==k
                width:=if saturated { d } else { d+1 }
                mut cost:=[256]i64{}
                mut deletion:=[16]i64{}
                for row in 0 .. d {
                    child:=children[16*vertex+row]
                    for col in 0 .. width {
                        index:=if col<child_count[child] { col } else { child_count[child] }
                        cost[16*row+col]=prices[col]+tables[16*child+index]
                    }
                }
                base:=tec_assignment(d,width,cost,mut deletion)
                if base<0 { return -1 }
                if saturated { tables[16*vertex]=base } else {
                    for col in 0 .. width { tables[16*vertex+col]=deletion[col] }
                }
            }
            vertex--
        }
        if child_count[0]==k { return tables[0] }
        return tables[child_count[0]]
    }
}
