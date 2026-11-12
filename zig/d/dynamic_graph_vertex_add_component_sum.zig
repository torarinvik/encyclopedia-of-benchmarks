const std = @import("std");

const max_n: usize = 16;
const max_q: usize = 32;
const max_ops: usize = max_n + 2 * max_q;
const tree_nodes: usize = 4 * max_q + 8;

const TimeOp = struct { kind: usize, a: usize, b: usize, delta: i64 };
const Change = struct { kind: u8, a: usize, root: usize, old_size: usize, old_sum: i64 };

fn rootOf(parent: *const [max_n]usize, input_vertex: usize) usize {
    var v = input_vertex;
    while (parent[v] != v) v = parent[v];
    return v;
}
fn place(node: usize, left: usize, right: usize, ql: usize, qr: usize, id: usize,
    count: *[tree_nodes]usize, bucket: *[tree_nodes * max_ops]usize) void {
    if (ql <= left and right <= qr) { bucket[node * max_ops + count[node]] = id; count[node] += 1; return; }
    const mid = left + (right-left)/2;
    if (ql < mid) place(node*2,left,mid,ql,qr,id,count,bucket);
    if (qr > mid) place(node*2+1,mid,right,ql,qr,id,count,bucket);
}
fn unite(u: usize, v: usize, parent: *[max_n]usize, size: *[max_n]usize,
    total: *[max_n]i64, history: *[max_ops]Change, hist_len: *usize) void {
    var ru = rootOf(parent,u); var rv = rootOf(parent,v);
    if (ru == rv) return;
    if (size[ru] < size[rv] or (size[ru] == size[rv] and ru > rv)) std.mem.swap(usize,&ru,&rv);
    history[hist_len.*] = .{ .kind=0, .a=rv, .root=ru, .old_size=size[ru], .old_sum=total[ru] };
    hist_len.* += 1; parent[rv]=ru; size[ru]+=size[rv]; total[ru]+=total[rv];
}
fn addValue(v: usize, delta: i64, parent: *[max_n]usize, total: *[max_n]i64,
    history: *[max_ops]Change, hist_len: *usize) void {
    const r = rootOf(parent,v);
    history[hist_len.*] = .{ .kind=1, .a=r, .root=0, .old_size=0, .old_sum=total[r] };
    hist_len.* += 1; total[r] += delta;
}
fn rollback(mark: usize, parent: *[max_n]usize, size: *[max_n]usize, total: *[max_n]i64,
    history: *[max_ops]Change, hist_len: *usize) void {
    while (hist_len.* > mark) {
        hist_len.* -= 1; const c=history[hist_len.*];
        if (c.kind == 0) { parent[c.a]=c.a; size[c.root]=c.old_size; total[c.root]=c.old_sum; }
        else total[c.a]=c.old_sum;
    }
}
fn visit(node: usize, left: usize, right: usize, ops: *const [max_ops]TimeOp,
    count: *const [tree_nodes]usize, bucket: *const [tree_nodes * max_ops]usize,
    event_op: *const [max_q]i64, event_a: *const [max_q]i64,
    parent: *[max_n]usize, size: *[max_n]usize, total: *[max_n]i64,
    history: *[max_ops]Change, hist_len: *usize, answer: *[max_q]i64) void {
    const mark=hist_len.*;
    for (0..count[node]) |i| { const op=ops[bucket[node*max_ops+i]]; if (op.kind==0) unite(op.a,op.b,parent,size,total,history,hist_len) else addValue(op.a,op.delta,parent,total,history,hist_len); }
    if (right-left==1) { if (event_op[left]==3) answer[left]=total[rootOf(parent,@intCast(event_a[left]))]; }
    else { const mid=left+(right-left)/2; visit(node*2,left,mid,ops,count,bucket,event_op,event_a,parent,size,total,history,hist_len,answer); visit(node*2+1,mid,right,ops,count,bucket,event_op,event_a,parent,size,total,history,hist_len,answer); }
    rollback(mark,parent,size,total,history,hist_len);
}
fn storeLe(out: [*]u8, off: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| out[off+i]=@truncate(bits >> @intCast(8*i));
}

export fn dynamic_graph_vertex_add_component_sum(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt==null or length<2 or length>2+max_n+3*max_q+1) return -1;
    const input=input_opt.?;
    if (input[0]<1 or input[0]>@as(i64,@intCast(max_n)) or input[1]<0 or input[1]>@as(i64,@intCast(max_q))) return -1;
    const n:usize=@intCast(input[0]); const q:usize=@intCast(input[1]);
    if (length!=2+n+3*q) return -1;
    var initial=[_]i64{0} ** max_n;
    for (0..n) |v| { initial[v]=input[2+v]; if (initial[v]<0 or initial[v]>100) return -1; }
    var event_op=[_]i64{0} ** max_q; var event_a=[_]i64{0} ** max_q; var event_b=[_]i64{0} ** max_q;
    var active=[_]bool{false} ** (max_n*max_n); var start=[_]usize{0} ** (max_n*max_n);
    var ops=[_]TimeOp{.{.kind=0,.a=0,.b=0,.delta=0}} ** max_ops;
    var il=[_]usize{0} ** max_ops; var ir=[_]usize{0} ** max_ops; var op_count:usize=0; var query_count:usize=0;
    for (0..q) |t| {
        const off=2+n+3*t; const op=input[off]; const a=input[off+1]; const b=input[off+2];
        event_op[t]=op; event_a[t]=a; event_b[t]=b;
        if (op==0 or op==1) {
            if (a<0 or a>=@as(i64,@intCast(n)) or b<0 or b>=@as(i64,@intCast(n)) or a==b) return -1;
            var u:usize=@intCast(a); var v:usize=@intCast(b); if (u>v) std.mem.swap(usize,&u,&v); const ix=u*max_n+v;
            if (op==0) { if (active[ix]) return -1; active[ix]=true; start[ix]=t; }
            else { if (!active[ix]) return -1; active[ix]=false; if (start[ix]<t) { ops[op_count]=.{.kind=0,.a=u,.b=v,.delta=0}; il[op_count]=start[ix]; ir[op_count]=t; op_count+=1; } }
        } else if (op==2) {
            if (a<0 or a>=@as(i64,@intCast(n)) or b<0 or b>100) return -1;
            if (b!=0 and t<q) { ops[op_count]=.{.kind=1,.a=@intCast(a),.b=0,.delta=b}; il[op_count]=t; ir[op_count]=q; op_count+=1; }
        } else if (op==3) { if (a<0 or a>=@as(i64,@intCast(n)) or b!=0) return -1; query_count+=1; }
        else return -1;
    }
    for (0..n) |u| { var v=u+1; while (v<n) : (v+=1) { const ix=u*max_n+v; if (active[ix] and start[ix]<q) { ops[op_count]=.{.kind=0,.a=u,.b=v,.delta=0}; il[op_count]=start[ix]; ir[op_count]=q; op_count+=1; } } }
    if (q!=0) for (0..n) |v| { if (initial[v]!=0) { ops[op_count]=.{.kind=1,.a=v,.b=0,.delta=initial[v]}; il[op_count]=0; ir[op_count]=q; op_count+=1; } };
    const output=output_opt orelse return -2;
    if (capacity<8*query_count) return -2;
    var count=[_]usize{0} ** tree_nodes; var bucket=[_]usize{0} ** (tree_nodes*max_ops);
    if (q!=0) for (0..op_count) |i| { if (il[i]<ir[i]) place(1,0,q,il[i],ir[i],i,&count,&bucket); };
    var parent=[_]usize{0} ** max_n; var size=[_]usize{0} ** max_n; var total=[_]i64{0} ** max_n;
    for (0..n) |v| { parent[v]=v; size[v]=1; }
    var history=[_]Change{.{.kind=0,.a=0,.root=0,.old_size=0,.old_sum=0}} ** max_ops; var hist_len:usize=0; var answer=[_]i64{0} ** max_q;
    if (q!=0) visit(1,0,q,&ops,&count,&bucket,&event_op,&event_a,&parent,&size,&total,&history,&hist_len,&answer);
    var written:usize=0; for (0..q) |t| { if (event_op[t]==3) { storeLe(output,written,answer[t]); written+=8; } }
    return @intCast(written);
}
