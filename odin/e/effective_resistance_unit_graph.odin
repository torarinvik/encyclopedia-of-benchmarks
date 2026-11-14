// Uncompiled and unexecuted matrix-tree draft.
package effective_resistance_unit_graph
import "core:c"

resistance_minor :: proc(lap: [36]i64, n, first, second: int) -> i64 {
    a: [36]i64
    rows := 0
    for i := 0; i < n; i += 1 {
        if i == first || i == second { continue }
        col := 0
        for j := 0; j < n; j += 1 {
            if j != first && j != second { a[rows*6+col] = lap[i*6+j]; col += 1 }
        }
        rows += 1
    }
    if rows == 0 { return 1 }
    prev := i64(1)
    for k := 0; k < rows-1; k += 1 {
        pivot := a[k*6+k]
        if pivot == 0 { return 0 }
        for i := k+1; i < rows; i += 1 {
            for j := k+1; j < rows; j += 1 { a[i*6+j] = (a[i*6+j]*pivot-a[i*6+k]*a[k*6+j])/prev }
        }
        for i := k+1; i < rows; i += 1 { a[i*6+k] = 0 }
        prev = pivot
    }
    return a[(rows-1)*6+rows-1]
}
@(export)
effective_resistance_unit_graph :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 4 || length > 35 { return -1 }
    nv,mv,sv,tv := input[0],input[1],input[2],input[3]
    if nv<2 || nv>6 || mv<0 || mv>15 || sv<0 || sv>=nv || tv<0 || tv>=nv || sv==tv || length != c.size_t(4+2*mv) { return -1 }
    n,m,s,t := int(nv),int(mv),int(sv),int(tv)
    lap: [36]i64
    seen: [36]bool
    for i := 0; i < m; i += 1 {
        uv,vv := input[4+2*i],input[5+2*i]
        if uv<0 || uv>=nv || vv<0 || vv>=nv || uv==vv { return -1 }
        u,v := int(uv),int(vv)
        if seen[u*6+v] { return -1 }
        seen[u*6+v]=true;seen[v*6+u]=true
        lap[u*6+u]+=1;lap[v*6+v]+=1;lap[u*6+v]-=1;lap[v*6+u]-=1
    }
    trees := resistance_minor(lap,n,t,n)
    if trees <= 0 { return -1 }
    forests := resistance_minor(lap,n,s,t)
    a,b := trees,forests
    for b != 0 { r := a%b; a=b; b=r }
    return forests/a*65536+trees/a
}
