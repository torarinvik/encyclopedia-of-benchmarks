// Uncompiled and unexecuted matrix-tree draft.
fn resistanceMinor(lap: [36]i64, n: usize, first: usize, second: usize) i64 {
    var matrix = [_]i64{0} ** 36;
    var rows: usize = 0;
    for (0..n) |i| {
        if (i == first or i == second) continue;
        var col: usize = 0;
        for (0..n) |j| {
            if (j != first and j != second) { matrix[rows*6+col] = lap[i*6+j]; col += 1; }
        }
        rows += 1;
    }
    if (rows == 0) return 1;
    var prev: i64 = 1;
    for (0..rows-1) |k| {
        const pivot = matrix[k*6+k];
        if (pivot == 0) return 0;
        for (k+1..rows) |i| for (k+1..rows) |j| {
            matrix[i*6+j] = @divExact(matrix[i*6+j]*pivot-matrix[i*6+k]*matrix[k*6+j],prev);
        };
        for (k+1..rows) |i| { matrix[i*6+k] = 0; }
        prev = pivot;
    }
    return matrix[(rows-1)*6+rows-1];
}
export fn effective_resistance_unit_graph(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > 35) return -1;
    const input = input_opt.?;
    const nv=input[0];const mv=input[1];const sv=input[2];const tv=input[3];
    if (nv<2 or nv>6 or mv<0 or mv>15 or sv<0 or sv>=nv or tv<0 or tv>=nv or sv==tv) return -1;
    const n:usize=@intCast(nv);const m:usize=@intCast(mv);const s:usize=@intCast(sv);const t:usize=@intCast(tv);
    if (length != 4+2*m) return -1;
    var lap=[_]i64{0} ** 36;
    var seen=[_]bool{false} ** 36;
    for (0..m) |i| {
        const uv=input[4+2*i];const vv=input[5+2*i];
        if (uv<0 or uv>=nv or vv<0 or vv>=nv or uv==vv) return -1;
        const u:usize=@intCast(uv);const v:usize=@intCast(vv);
        if (seen[u*6+v]) return -1;
        seen[u*6+v]=true;seen[v*6+u]=true;
        lap[u*6+u]+=1;lap[v*6+v]+=1;lap[u*6+v]-=1;lap[v*6+u]-=1;
    }
    const trees=resistanceMinor(lap,n,t,n);
    if (trees<=0) return -1;
    const forests=resistanceMinor(lap,n,s,t);
    var a=trees;var b=forests;
    while (b!=0) { const r=@rem(a,b);a=b;b=r; }
    return @divExact(forests,a)*65536+@divExact(trees,a);
}
