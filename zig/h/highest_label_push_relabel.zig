export fn highest_label_push_relabel(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt==null or length<4 or length>197) return -1;
    const input=input_opt.?;
    const nv=input[0]; const mv=input[1]; const sv=input[2]; const tv=input[3];
    if (nv<2 or nv>16 or mv<0 or mv>64 or sv<1 or sv>nv or tv<1 or tv>nv or sv==tv) return -1;
    const n: usize=@intCast(nv); const m: usize=@intCast(mv);
    const source: usize=@intCast(sv-1); const sink: usize=@intCast(tv-1);
    if (length!=4+3*m) return -1;
    var residual: [16][16]i64=@splat(@splat(0));
    var excess: [16]i64=@splat(0);
    var height: [16]usize=@splat(0);
    for (0..m) |i| {
        const u=input[4+3*i]; const v=input[5+3*i]; const capacity=input[6+3*i];
        if (u<1 or u>nv or v<1 or v>nv or u==v or capacity<0 or capacity>100) return -1;
        residual[@intCast(u-1)][@intCast(v-1)]+=capacity;
    }
    height[source]=n;
    for (0..n) |v| {
        const amount=residual[source][v]; residual[source][v]=0;
        residual[v][source]+=amount; excess[v]+=amount; excess[source]-=amount;
    }
    while (true) {
        var active: ?usize=null;
        for (0..n) |v| {
            if (v!=source and v!=sink and excess[v]>0) {
                if (active==null) { active=v; }
                else if (height[v]>height[active.?]) { active=v; }
            }
        }
        const u=active orelse return excess[sink];
        var destination: ?usize=null;
        var minimum: usize=2*n+1;
        for (0..n) |v| {
            if (residual[u][v]>0) {
                minimum=@min(minimum,height[v]);
                if (destination==null and height[u]==height[v]+1) destination=v;
            }
        }
        if (destination) |v| {
            const amount=@min(excess[u],residual[u][v]);
            residual[u][v]-=amount; residual[v][u]+=amount; excess[u]-=amount; excess[v]+=amount;
        } else {
            if (minimum>2*n) return -1;
            height[u]=minimum+1;
        }
    }
}
