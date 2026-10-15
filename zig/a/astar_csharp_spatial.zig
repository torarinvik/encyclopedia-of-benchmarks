const MAX_NODES: usize = 16;
const Node = struct { x: f64 = 0, y: f64 = 0, multiplier: f64 = 1, current: f64 = 0, estimated: f64 = 0, traversable: bool = false, state: i32 = 0, parent: i32 = -1 };

fn distance(nodes: *const [MAX_NODES]Node, a: usize, b: usize) f64 {
    const dx = nodes[a].x - nodes[b].x;
    const dy = nodes[a].y - nodes[b].y;
    return @sqrt(dx * dx + dy * dy);
}
fn total(nodes: *const [MAX_NODES]Node, i: usize) f64 { return nodes[i].current + nodes[i].estimated; }
fn enqueue(heap: *[MAX_NODES]usize, count: *usize, value: usize, nodes: *const [MAX_NODES]Node) void {
    var i = count.*;
    count.* += 1;
    while (i > 0) { const p = (i - 1) / 2; if (total(nodes, heap[p]) <= total(nodes, value)) break; heap[i] = heap[p]; i = p; }
    heap[i] = value;
}
fn dequeue(heap: *[MAX_NODES]usize, count: *usize, nodes: *const [MAX_NODES]Node) usize {
    const target = heap[0]; count.* -= 1; const root = heap[count.*]; var i: usize = 0;
    while (i * 2 + 1 < count.*) { const left = i * 2 + 1; const right = i * 2 + 2; const child = if (right < count.* and total(nodes, heap[right]) < total(nodes, heap[left])) right else left;
        if (total(nodes, heap[child]) >= total(nodes, root)) break; heap[i] = heap[child]; i = child; }
    if (count.* > 0) heap[i] = root;
    return target;
}
fn putI64(out: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |b| out[offset+b] = @truncate(bits >> @intCast(b*8)); }

pub export fn astar_csharp_spatial(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 4) return -1;
    const n64=input[0]; const m64=input[1]; const s64=input[2]; const g64=input[3];
    if (n64 < 2 or n64 > 16 or m64 != n64-1 or s64 < 0 or s64 >= n64 or g64 < 0 or g64 >= n64) return -1;
    const n: usize=@intCast(n64); const m: usize=@intCast(m64); const start: usize=@intCast(s64); const goal: usize=@intCast(g64); const edge: usize=4+4*n;
    if (length != 4+4*n+2*m) return -1;
    var nodes: [MAX_NODES]Node = [_]Node{.{}} ** MAX_NODES;
    var parents: [MAX_NODES]usize = [_]usize{0} ** MAX_NODES;
    var seen: [MAX_NODES]bool = [_]bool{false} ** MAX_NODES;
    var stack: [MAX_NODES]usize = undefined;
    for (0..n) |i| { const o=4+4*i; const x=input[o]; const y=input[o+1]; const t=input[o+2]; const multiplier=input[o+3];
        if (x < -1000 or x > 1000 or y < -1000 or y > 1000 or (t != 0 and t != 1) or multiplier < 1 or multiplier > 4) return -1;
        nodes[i] = .{ .x=@floatFromInt(x), .y=@floatFromInt(y), .multiplier=@floatFromInt(multiplier), .traversable=t==1 };
        for (0..i) |j| if (nodes[i].x==nodes[j].x and nodes[i].y==nodes[j].y) return -1;
    }
    for (0..m) |e| { const u=input[edge+2*e]; const v=input[edge+2*e+1]; if (u<0 or u>=n64 or v<0 or v>=n64 or u==v) return -1; const vi:usize=@intCast(v); parents[vi]+=1; if (parents[vi]>1) return -1;
        for (0..e) |p| if(input[edge+2*p]==u and input[edge+2*p+1]==v) return -1;
    }
    if (parents[start]!=0) return -1; for(0..n)|i|{if(i!=start and parents[i]!=1)return -1;}
    var top:usize=1;var visited:usize=0;stack[0]=start;while(top>0){top-=1;const u=stack[top];if(seen[u])continue;seen[u]=true;visited+=1;for(0..m)|e|{if(input[edge+2*e]==@as(i64,@intCast(u))){stack[top]=@intCast(input[edge+2*e+1]);top+=1;}}}if(visited!=n)return -1;
    var heap:[MAX_NODES]usize=undefined;var hc:usize=0;for(0..m)|e|{if(input[edge+2*e]==@as(i64,@intCast(start))){const v:usize=@intCast(input[edge+2*e+1]);if(nodes[v].traversable){nodes[v].current=distance(&nodes,start,v)*nodes[v].multiplier;nodes[v].estimated=distance(&nodes,v,goal);enqueue(&heap,&hc,v,&nodes);}}}
    var path:[MAX_NODES]usize=undefined;var pc:usize=0;while(hc>0){const u=dequeue(&heap,&hc,&nodes);nodes[u].state=2;if(total(&nodes,u)==total(&nodes,goal)){var q:i32=@intCast(goal);while(q>=0 and pc<MAX_NODES){path[pc]=@intCast(q);pc+=1;q=nodes[@intCast(q)].parent;}break;}
        for(0..m)|e|{if(input[edge+2*e]!=@as(i64,@intCast(u)))continue;const v:usize=@intCast(input[edge+2*e+1]);if(!nodes[v].traversable or nodes[v].state==2)continue;if(nodes[v].state==0){nodes[v].parent=@intCast(u);nodes[v].current=nodes[u].current+distance(&nodes,u,v)*nodes[v].multiplier;nodes[v].estimated=nodes[v].current+distance(&nodes,v,goal);nodes[v].state=1;enqueue(&heap,&hc,v,&nodes);}else if(total(&nodes,u)!=total(&nodes,v)){const ng=nodes[u].current+distance(&nodes,u,v);const nf=ng+nodes[u].estimated;if(nf<total(&nodes,v)){nodes[v].parent=@intCast(u);nodes[v].current=ng;}}else{return -1;}}
    }
    const bytes=pc*8;if(bytes==0)return 0;if(output==null or capacity<bytes)return -2;for(0..pc)|i|putI64(output,i*8,@intCast(path[pc-1-i]));return @intCast(bytes);
}
