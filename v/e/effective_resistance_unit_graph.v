// Uncompiled and unexecuted matrix-tree draft.
module effective_resistance_unit_graph
fn resistance_minor(lap [36]i64, n int, first int, second int) i64 {
    mut a := [36]i64{}
    mut rows := 0
    for i in 0 .. n {
        if i == first || i == second { continue }
        mut col := 0
        for j in 0 .. n {
            if j != first && j != second { a[rows*6+col]=lap[i*6+j]; col++ }
        }
        rows++
    }
    if rows == 0 { return 1 }
    mut prev := i64(1)
    for k in 0 .. rows-1 {
        pivot := a[k*6+k]
        if pivot == 0 { return 0 }
        for i in k+1 .. rows { for j in k+1 .. rows { a[i*6+j]=(a[i*6+j]*pivot-a[i*6+k]*a[k*6+j])/prev } }
        for i in k+1 .. rows { a[i*6+k]=0 }
        prev=pivot
    }
    return a[(rows-1)*6+rows-1]
}
@[export: 'effective_resistance_unit_graph']
pub fn effective_resistance_unit_graph(input &i64, length usize) i64 {
    unsafe {
        if input == nil || length<4 || length>35 { return -1 }
        nv:=input[0];mv:=input[1];sv:=input[2];tv:=input[3]
        if nv<2 || nv>6 || mv<0 || mv>15 || sv<0 || sv>=nv || tv<0 || tv>=nv || sv==tv || length!=usize(4+2*mv) { return -1 }
        n:=int(nv);m:=int(mv);s:=int(sv);t:=int(tv)
        mut lap := [36]i64{}
        mut seen := [36]bool{}
        for i in 0 .. m {
            uv:=input[4+2*i];vv:=input[5+2*i]
            if uv<0 || uv>=nv || vv<0 || vv>=nv || uv==vv { return -1 }
            u:=int(uv);v:=int(vv)
            if seen[u*6+v] { return -1 }
            seen[u*6+v]=true;seen[v*6+u]=true
            lap[u*6+u]++;lap[v*6+v]++;lap[u*6+v]--;lap[v*6+u]--
        }
        trees:=resistance_minor(lap,n,t,-1)
        if trees<=0 { return -1 }
        forests:=resistance_minor(lap,n,s,t)
        mut a:=trees;mut b:=forests
        for b!=0 { r:=a%b; a=b; b=r }
        return forests/a*65536+trees/a
    }
}
