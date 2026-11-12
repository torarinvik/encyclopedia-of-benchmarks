from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 16
alias MAX_Q = 32
alias MAX_OPS = MAX_N + 2 * MAX_Q
alias TREE_NODES = 4 * MAX_Q + 8

fn dg_root(parent: InlineArray[Int, MAX_N], input_vertex: Int) -> Int:
    var v = input_vertex
    while parent[v] != v: v = parent[v]
    return v

fn dg_place(node: Int, left: Int, right: Int, ql: Int, qr: Int, id: Int,
    mut count: InlineArray[Int, TREE_NODES], mut buckets: InlineArray[Int, TREE_NODES * MAX_OPS]):
    if ql <= left and right <= qr:
        buckets[node * MAX_OPS + count[node]] = id
        count[node] += 1
        return
    let mid = left + (right-left)//2
    if ql < mid: dg_place(node*2,left,mid,ql,qr,id,mut count,mut buckets)
    if qr > mid: dg_place(node*2+1,mid,right,ql,qr,id,mut count,mut buckets)

fn dg_unite(u: Int, v: Int, mut parent: InlineArray[Int, MAX_N],
    mut size: InlineArray[Int, MAX_N], mut total: InlineArray[Int64, MAX_N],
    mut hist_kind: InlineArray[Int, MAX_OPS], mut hist_a: InlineArray[Int, MAX_OPS],
    mut hist_b: InlineArray[Int, MAX_OPS], mut hist_size: InlineArray[Int, MAX_OPS],
    mut hist_sum: InlineArray[Int64, MAX_OPS], mut hist_len: Int):
    var ru = dg_root(parent,u); var rv = dg_root(parent,v)
    if ru == rv: return
    if size[ru] < size[rv] or (size[ru] == size[rv] and ru > rv):
        let tmp=ru; ru=rv; rv=tmp
    hist_kind[hist_len]=0; hist_a[hist_len]=rv; hist_b[hist_len]=ru
    hist_size[hist_len]=size[ru]; hist_sum[hist_len]=total[ru]; hist_len+=1
    parent[rv]=ru; size[ru]+=size[rv]; total[ru]+=total[rv]

fn dg_add(v: Int, delta: Int64, parent: InlineArray[Int, MAX_N],
    mut total: InlineArray[Int64, MAX_N], mut hist_kind: InlineArray[Int, MAX_OPS],
    mut hist_a: InlineArray[Int, MAX_OPS], mut hist_sum: InlineArray[Int64, MAX_OPS],
    mut hist_len: Int):
    let r=dg_root(parent,v)
    hist_kind[hist_len]=1; hist_a[hist_len]=r; hist_sum[hist_len]=total[r]
    hist_len+=1; total[r]+=delta

fn dg_rollback(mark: Int, mut parent: InlineArray[Int, MAX_N], mut size: InlineArray[Int, MAX_N],
    mut total: InlineArray[Int64, MAX_N], hist_kind: InlineArray[Int, MAX_OPS],
    hist_a: InlineArray[Int, MAX_OPS], hist_b: InlineArray[Int, MAX_OPS],
    hist_size: InlineArray[Int, MAX_OPS], hist_sum: InlineArray[Int64, MAX_OPS],
    mut hist_len: Int):
    while hist_len > mark:
        hist_len-=1
        let k=hist_kind[hist_len]; let a=hist_a[hist_len]
        if k==0:
            let r=hist_b[hist_len]; parent[a]=a; size[r]=hist_size[hist_len]; total[r]=hist_sum[hist_len]
        else: total[a]=hist_sum[hist_len]

fn dg_visit(node: Int, left: Int, right: Int,
    kind: InlineArray[Int, MAX_OPS], op_a: InlineArray[Int, MAX_OPS],
    op_b: InlineArray[Int, MAX_OPS], delta: InlineArray[Int64, MAX_OPS],
    count: InlineArray[Int, TREE_NODES], buckets: InlineArray[Int, TREE_NODES * MAX_OPS],
    event_op: InlineArray[Int64, MAX_Q], event_a: InlineArray[Int64, MAX_Q],
    mut parent: InlineArray[Int, MAX_N], mut size: InlineArray[Int, MAX_N],
    mut total: InlineArray[Int64, MAX_N], mut hist_kind: InlineArray[Int, MAX_OPS],
    mut hist_a: InlineArray[Int, MAX_OPS], mut hist_b: InlineArray[Int, MAX_OPS],
    mut hist_size: InlineArray[Int, MAX_OPS], mut hist_sum: InlineArray[Int64, MAX_OPS],
    mut hist_len: Int, mut answer: InlineArray[Int64, MAX_Q]):
    let mark=hist_len
    for i in range(count[node]):
        let id=buckets[node*MAX_OPS+i]
        if kind[id]==0:
            dg_unite(op_a[id],op_b[id],mut parent,mut size,mut total,mut hist_kind,mut hist_a,mut hist_b,mut hist_size,mut hist_sum,mut hist_len)
        else:
            dg_add(op_a[id],delta[id],parent,mut total,mut hist_kind,mut hist_a,mut hist_sum,mut hist_len)
    if right-left==1:
        if event_op[left]==3: answer[left]=total[dg_root(parent,Int(event_a[left]))]
    else:
        let mid=left+(right-left)//2
        dg_visit(node*2,left,mid,kind,op_a,op_b,delta,count,buckets,event_op,event_a,mut parent,mut size,mut total,mut hist_kind,mut hist_a,mut hist_b,mut hist_size,mut hist_sum,mut hist_len,mut answer)
        dg_visit(node*2+1,mid,right,kind,op_a,op_b,delta,count,buckets,event_op,event_a,mut parent,mut size,mut total,mut hist_kind,mut hist_a,mut hist_b,mut hist_size,mut hist_sum,mut hist_len,mut answer)
    dg_rollback(mark,mut parent,mut size,mut total,hist_kind,hist_a,hist_b,hist_size,hist_sum,mut hist_len)

fn dg_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=bitcast[UInt64](value)
    for i in range(8): output[offset+i]=UInt8((bits >> UInt(8*i)) & 255)

@export("dynamic_graph_vertex_add_component_sum")
fn dynamic_graph_vertex_add_component_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length<2 or length>2+MAX_N+3*MAX_Q+1: return -1
    let nn=input[0]; let qq=input[1]
    if nn<1 or nn>MAX_N or qq<0 or qq>MAX_Q: return -1
    let n=Int(nn); let q=Int(qq)
    if length!=c_size_t(2+n+3*q): return -1
    var initial=InlineArray[Int64, MAX_N]()
    for v in range(n):
        initial[v]=input[2+v]
        if initial[v]<0 or initial[v]>100: return -1
    var event_op=InlineArray[Int64, MAX_Q](); var event_a=InlineArray[Int64, MAX_Q](); var event_b=InlineArray[Int64, MAX_Q]()
    var active=InlineArray[Int, MAX_N*MAX_N](); var start=InlineArray[Int, MAX_N*MAX_N]()
    var kind=InlineArray[Int, MAX_OPS](); var op_a=InlineArray[Int, MAX_OPS](); var op_b=InlineArray[Int, MAX_OPS](); var delta=InlineArray[Int64, MAX_OPS]()
    var il=InlineArray[Int, MAX_OPS](); var ir=InlineArray[Int, MAX_OPS](); var op_count=0; var query_count=0
    for t in range(q):
        let off=2+n+3*t; let op=input[off]; let a=input[off+1]; let b=input[off+2]
        event_op[t]=op; event_a[t]=a; event_b[t]=b
        if op==0 or op==1:
            if a<0 or a>=nn or b<0 or b>=nn or a==b: return -1
            var u=Int(a); var v=Int(b)
            if u>v: let tmp=u; u=v; v=tmp
            let ix=u*MAX_N+v
            if op==0:
                if active[ix]!=0: return -1
                active[ix]=1; start[ix]=t
            else:
                if active[ix]==0: return -1
                active[ix]=0
                if start[ix]<t:
                    kind[op_count]=0; op_a[op_count]=u; op_b[op_count]=v; il[op_count]=start[ix]; ir[op_count]=t; op_count+=1
        elif op==2:
            if a<0 or a>=nn or b<0 or b>100: return -1
            if b!=0 and t<q:
                kind[op_count]=1; op_a[op_count]=Int(a); delta[op_count]=b; il[op_count]=t; ir[op_count]=q; op_count+=1
        elif op==3:
            if a<0 or a>=nn or b!=0: return -1
            query_count+=1
        else: return -1
    for u in range(n):
        for v in range(u+1,n):
            let ix=u*MAX_N+v
            if active[ix]!=0 and start[ix]<q:
                kind[op_count]=0; op_a[op_count]=u; op_b[op_count]=v; il[op_count]=start[ix]; ir[op_count]=q; op_count+=1
    if q!=0:
        for v in range(n):
            if initial[v]!=0: kind[op_count]=1; op_a[op_count]=v; delta[op_count]=initial[v]; il[op_count]=0; ir[op_count]=q; op_count+=1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity<c_size_t(8*query_count): return -2
    var count=InlineArray[Int, TREE_NODES](); var bucket=InlineArray[Int, TREE_NODES*MAX_OPS]()
    if q!=0:
        for i in range(op_count):
            if il[i]<ir[i]: dg_place(1,0,q,il[i],ir[i],i,mut count,mut bucket)
    var parent=InlineArray[Int, MAX_N](); var size=InlineArray[Int, MAX_N](); var total=InlineArray[Int64, MAX_N]()
    for v in range(n): parent[v]=v; size[v]=1
    var hk=InlineArray[Int, MAX_OPS](); var ha=InlineArray[Int, MAX_OPS](); var hb=InlineArray[Int, MAX_OPS](); var hs=InlineArray[Int, MAX_OPS](); var hv=InlineArray[Int64, MAX_OPS](); var hist_len=0
    var answer=InlineArray[Int64, MAX_Q]()
    if q!=0: dg_visit(1,0,q,kind,op_a,op_b,delta,count,bucket,event_op,event_a,mut parent,mut size,mut total,mut hk,mut ha,mut hb,mut hs,mut hv,mut hist_len,mut answer)
    var written=0
    for t in range(q):
        if event_op[t]==3: dg_store(output,written,answer[t]); written+=8
    return Int64(written)
