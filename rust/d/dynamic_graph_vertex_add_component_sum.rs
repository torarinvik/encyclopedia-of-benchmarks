use core::ffi::c_uchar;
use core::ptr;

const NMAX: usize = 16;
const QMAX: usize = 32;
const OMAX: usize = NMAX + 2 * QMAX;
const TMAX: usize = 4 * QMAX + 8;

#[derive(Clone, Copy, Default)]
struct Op { kind: usize, a: usize, b: usize, delta: i64 }
#[derive(Clone, Copy, Default)]
struct Change { kind: u8, child_or_root: usize, root: usize, old_size: usize, old_sum: i64 }
struct Dsu {
    parent: [usize; NMAX], size: [usize; NMAX], sum: [i64; NMAX],
    history: [Change; OMAX], len: usize,
}
impl Dsu {
    fn root(&self, mut v: usize) -> usize { while self.parent[v] != v { v = self.parent[v]; } v }
    fn unite(&mut self, u: usize, v: usize) {
        let (mut ru, mut rv) = (self.root(u), self.root(v));
        if ru == rv { return; }
        if self.size[ru] < self.size[rv] || (self.size[ru] == self.size[rv] && ru > rv) { core::mem::swap(&mut ru, &mut rv); }
        self.history[self.len] = Change { kind: 0, child_or_root: rv, root: ru, old_size: self.size[ru], old_sum: self.sum[ru] };
        self.len += 1;
        self.parent[rv] = ru; self.size[ru] += self.size[rv]; self.sum[ru] += self.sum[rv];
    }
    fn add_value(&mut self, v: usize, delta: i64) {
        let r = self.root(v);
        self.history[self.len] = Change { kind: 1, child_or_root: r, root: 0, old_size: 0, old_sum: self.sum[r] };
        self.len += 1; self.sum[r] += delta;
    }
    fn rollback(&mut self, mark: usize) {
        while self.len > mark {
            self.len -= 1; let c = self.history[self.len];
            if c.kind == 0 { self.parent[c.child_or_root] = c.child_or_root; self.size[c.root] = c.old_size; self.sum[c.root] = c.old_sum; }
            else { self.sum[c.child_or_root] = c.old_sum; }
        }
    }
}

fn place(node: usize, l: usize, r: usize, ql: usize, qr: usize, id: usize,
         count: &mut [usize; TMAX], bucket: &mut [[usize; OMAX]; TMAX]) {
    if ql <= l && r <= qr { bucket[node][count[node]] = id; count[node] += 1; return; }
    let mid = l + (r-l)/2;
    if ql < mid { place(node*2,l,mid,ql,qr,id,count,bucket); }
    if qr > mid { place(node*2+1,mid,r,ql,qr,id,count,bucket); }
}

fn visit(node: usize, l: usize, r: usize, ops: &[Op; OMAX], count: &[usize; TMAX],
         bucket: &[[usize; OMAX]; TMAX], event_op: &[i64; QMAX], event_a: &[i64; QMAX],
         dsu: &mut Dsu, answer: &mut [i64; QMAX]) {
    let mark = dsu.len;
    for i in 0..count[node] { let op = ops[bucket[node][i]]; if op.kind == 0 { dsu.unite(op.a,op.b); } else { dsu.add_value(op.a,op.delta); } }
    if r-l == 1 { if event_op[l] == 3 { answer[l] = dsu.sum[dsu.root(event_a[l] as usize)]; } }
    else { let mid=l+(r-l)/2; visit(node*2,l,mid,ops,count,bucket,event_op,event_a,dsu,answer); visit(node*2+1,mid,r,ops,count,bucket,event_op,event_a,dsu,answer); }
    dsu.rollback(mark);
}

unsafe fn read(input: *const i64, index: usize) -> i64 { *input.add(index) }

#[no_mangle]
pub unsafe extern "C" fn dynamic_graph_vertex_add_component_sum(
    input: *const i64, length: usize, output: *mut c_uchar, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 2 + NMAX + 3*QMAX + 1 { return -1; }
    let nn=read(input,0); let qq=read(input,1);
    if nn<1 || nn>NMAX as i64 || qq<0 || qq>QMAX as i64 { return -1; }
    let n=nn as usize; let q=qq as usize;
    if length != 2+n+3*q { return -1; }
    let mut initial=[0i64;NMAX];
    for v in 0..n { initial[v]=read(input,2+v); if !(0..=100).contains(&initial[v]) { return -1; } }
    let mut event_op=[0i64;QMAX]; let mut event_a=[0i64;QMAX]; let mut event_b=[0i64;QMAX];
    let mut active=[[false;NMAX];NMAX]; let mut start=[[0usize;NMAX];NMAX];
    let mut ops=[Op::default();OMAX]; let mut il=[0usize;OMAX]; let mut ir=[0usize;OMAX]; let mut op_count=0usize; let mut query_count=0usize;
    for t in 0..q {
        let off=2+n+3*t; let op=read(input,off); let a=read(input,off+1); let b=read(input,off+2);
        event_op[t]=op; event_a[t]=a; event_b[t]=b;
        if op==0 || op==1 {
            if a<0 || a>=nn || b<0 || b>=nn || a==b { return -1; }
            let (mut u,mut v)=(a as usize,b as usize); if u>v { core::mem::swap(&mut u,&mut v); }
            if op==0 { if active[u][v] { return -1; } active[u][v]=true; start[u][v]=t; }
            else { if !active[u][v] { return -1; } active[u][v]=false; if start[u][v]<t { ops[op_count]=Op{kind:0,a:u,b:v,delta:0}; il[op_count]=start[u][v]; ir[op_count]=t; op_count+=1; } }
        } else if op==2 {
            if a<0 || a>=nn || b<0 || b>100 { return -1; }
            if b!=0 && t<q { ops[op_count]=Op{kind:1,a:a as usize,b:0,delta:b}; il[op_count]=t; ir[op_count]=q; op_count+=1; }
        } else if op==3 { if a<0 || a>=nn || b!=0 { return -1; } query_count+=1; }
        else { return -1; }
    }
    for u in 0..n { for v in u+1..n { if active[u][v] && start[u][v]<q { ops[op_count]=Op{kind:0,a:u,b:v,delta:0}; il[op_count]=start[u][v]; ir[op_count]=q; op_count+=1; } } }
    if q!=0 { for v in 0..n { if initial[v]!=0 { ops[op_count]=Op{kind:1,a:v,b:0,delta:initial[v]}; il[op_count]=0; ir[op_count]=q; op_count+=1; } } }
    if output.is_null() || capacity < 8*query_count { return -2; }
    let mut count=[0usize;TMAX]; let mut bucket=[[0usize;OMAX];TMAX];
    if q!=0 { for i in 0..op_count { if il[i]<ir[i] { place(1,0,q,il[i],ir[i],i,&mut count,&mut bucket); } } }
    let mut dsu=Dsu{parent:[0;NMAX],size:[0;NMAX],sum:[0;NMAX],history:[Change::default();OMAX],len:0};
    for v in 0..n { dsu.parent[v]=v; dsu.size[v]=1; }
    let mut answer=[0i64;QMAX]; if q!=0 { visit(1,0,q,&ops,&count,&bucket,&event_op,&event_a,&mut dsu,&mut answer); }
    let mut written=0usize;
    for t in 0..q { if event_op[t]==3 { let bits=answer[t] as u64; for b in 0..8 { *output.add(written+b)=(bits>>(8*b)) as u8; } written+=8; } }
    written as i64
}
