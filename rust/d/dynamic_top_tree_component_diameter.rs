use core::ffi::c_uchar;

const N: usize = 16;
const Q: usize = 32;
const E: usize = 15;
const K: usize = 75;
const INPUT_MAX: usize = 143;
const LIMIT: i64 = 1000;
const EDGE: i16 = 0;
const COMPRESS: i16 = 1;
const RAKE_ZERO: i16 = 2;
const RAKE_MERGE: i16 = 3;
const RAKE_BRANCH: i16 = 4;

#[derive(Clone, Copy, Default)]
struct Node {
    kind: i16, a: i16, b: i16, c: i16, parent: i16,
    end0: i16, end1: i16, pivot: i16, edge: i16,
    len: i64, far0: i64, far1: i64, diam: i64, best1: i64, best2: i64,
}

fn far_at(nodes: &[Node; K], id: usize, vertex: i16) -> i64 {
    if nodes[id].end0 == vertex { nodes[id].far0 } else { nodes[id].far1 }
}

fn recalc(nodes: &mut [Node; K], id: usize, weights: &[i64; E]) {
    let x = nodes[id];
    let mut out = x;
    match x.kind {
        EDGE => { let w = weights[x.edge as usize]; out.len=w; out.far0=w; out.far1=w; out.diam=w; }
        RAKE_ZERO => { out.best1=0; out.best2=0; out.diam=0; }
        RAKE_MERGE => {
            let l=nodes[x.a as usize]; let r=nodes[x.b as usize];
            let mut first=0i64; let mut second=0i64;
            for arm in [l.best1,l.best2,r.best1,r.best2] {
                if arm >= first { second=first; first=arm; } else if arm > second { second=arm; }
            }
            out.best1=first; out.best2=second; out.diam=l.diam.max(r.diam).max(l.best1+r.best1);
        }
        RAKE_BRANCH => {
            let e=nodes[x.a as usize]; let local=nodes[x.b as usize];
            let center=far_at(nodes,x.a as usize,x.end0); let pivot=far_at(nodes,x.a as usize,x.pivot);
            out.best1=center.max(e.len+local.best1); out.best2=0;
            out.diam=e.diam.max(local.diam).max(pivot+local.best1);
        }
        _ => {
            let a=nodes[x.a as usize]; let b=nodes[x.b as usize]; let local=nodes[x.c as usize];
            let (y,z,p)=(x.end0,x.end1,x.pivot);
            let ay=far_at(nodes,x.a as usize,y); let ap=far_at(nodes,x.a as usize,p);
            let bp=far_at(nodes,x.b as usize,p); let bz=far_at(nodes,x.b as usize,z);
            out.len=a.len+b.len;
            out.far0=ay.max(a.len+bp.max(local.best1));
            out.far1=bz.max(b.len+ap.max(local.best1));
            out.diam=a.diam.max(b.diam).max(local.diam).max(ap+bp).max(ap+local.best1).max(bp+local.best1);
        }
    }
    nodes[id]=out;
}

fn append(nodes: &mut [Node; K], count: &mut usize, kind: i16, weights: &[i64; E],
          a: i16, b: i16, c: i16, end0: i16, end1: i16, pivot: i16, edge: i16) -> i16 {
    if *count >= K { return -1; }
    let id=*count; *count+=1;
    nodes[id]=Node { kind,a,b,c,parent:-1,end0,end1,pivot,edge,..Node::default() };
    for child in [a,b,c] { if child>=0 { nodes[child as usize].parent=id as i16; } }
    recalc(nodes,id,weights); id as i16
}

fn make_rake(nodes: &mut [Node; K], count: &mut usize, weights: &[i64; E],
             base: i16, branches: &[i16; N], branch_count: usize) -> i16 {
    let mut level=[-1i16; N+1]; let mut next=[-1i16; N+1];
    let mut len=1; level[0]=base;
    for i in 0..branch_count { level[len]=branches[i]; len+=1; }
    while len>1 {
        let mut next_len=0; let mut i=0;
        while i<len {
            if i+1==len { next[next_len]=level[i]; next_len+=1; }
            else {
                let merged=append(nodes,count,RAKE_MERGE,weights,level[i],level[i+1],-1,-1,-1,-1,-1);
                if merged<0 { return -1; }
                next[next_len]=merged; next_len+=1;
            }
            i+=2;
        }
        level[..next_len].copy_from_slice(&next[..next_len]); len=next_len;
    }
    level[0]
}

fn neighbors(adj: &[[bool; N]; N], active: &[bool; N], n: usize, v: usize, out: &mut [usize; 2]) -> usize {
    let mut count=0;
    for u in 0..n { if active[u] && adj[v][u] { if count<2 { out[count]=u; } count+=1; } }
    count
}

unsafe fn read(input: *const i64, index: usize) -> i64 { *input.add(index) }
fn find(parent: &mut [usize; N], mut v: usize) -> usize {
    while parent[v]!=v { parent[v]=parent[parent[v]]; v=parent[v]; } v
}
fn store_le(output: *mut u8, offset: usize, value: i64) {
    let bits=value as u64;
    for byte in 0..8 { unsafe { *output.add(offset+byte)=(bits>>(8*byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn dynamic_top_tree_component_diameter(
    input: *const i64, length: usize, output: *mut c_uchar, capacity: usize) -> i64 {
    if input.is_null() || length<2 || length>INPUT_MAX { return -1; }
    let nn=read(input,0); let qq=read(input,1);
    if nn<1 || nn>N as i64 || qq<0 || qq>Q as i64 { return -1; }
    let n=nn as usize; let q=qq as usize; let edge_end=2+3*(n-1);
    if length!=edge_end+3*q { return -1; }
    let mut eu=[0usize;E]; let mut ev=[0usize;E]; let mut dsu=[0usize;N]; let mut weights=[0i64;E];
    for v in 0..n { dsu[v]=v; }
    for e in 0..n-1 {
        let off=2+3*e; let (u,v,w)=(read(input,off),read(input,off+1),read(input,off+2));
        if u<0 || u>=nn || v<0 || v>=nn || u==v || w<0 || w>LIMIT { return -1; }
        let (u,v)=(u as usize,v as usize); let ru=find(&mut dsu,u); let rv=find(&mut dsu,v);
        if ru==rv { return -1; } dsu[ru]=rv; eu[e]=u; ev[e]=v; weights[e]=w;
    }
    let root=find(&mut dsu,0); for v in 1..n { if find(&mut dsu,v)!=root { return -1; } }
    let mut op_code=[0i64;Q]; let mut op_edge=[0usize;Q]; let mut op_value=[0i64;Q]; let mut query_count=0usize;
    for t in 0..q {
        let off=edge_end+3*t; let (op,e,val)=(read(input,off),read(input,off+1),read(input,off+2));
        if op==0 { if e<0 || e>=n as i64-1 || val<0 || val>LIMIT { return -1; } }
        else if op==1 { if e!=0 || val!=0 { return -1; } query_count+=1; }
        else { return -1; }
        op_code[t]=op; op_edge[t]=e as usize; op_value[t]=val;
    }
    let out_bytes=8*query_count;
    if out_bytes>0 && (output.is_null() || capacity<out_bytes) { return -2; }

    let mut nodes=[Node::default();K]; let mut count=0usize;
    let mut base_rake=[-1i16;N]; let mut base_edge=[-1i16;E];
    let mut adj=[[false;N];N]; let mut active=[false;N];
    let mut edge_cluster=[[-1i16;N];N]; let mut branches=[[-1i16;N];N]; let mut branch_count=[0usize;N];
    for v in 0..n { active[v]=true; base_rake[v]=append(&mut nodes,&mut count,RAKE_ZERO,&weights,-1,-1,-1,-1,-1,-1,-1); if base_rake[v]<0{return -1;} }
    for e in 0..n-1 {
        let u=eu[e]; let v=ev[e]; let cluster=append(&mut nodes,&mut count,EDGE,&weights,-1,-1,-1,u as i16,v as i16,-1,e as i16);
        if cluster<0{return -1;} base_edge[e]=cluster; adj[u][v]=true; adj[v][u]=true; edge_cluster[u][v]=cluster; edge_cluster[v][u]=cluster;
    }
    let mut active_count=n;
    while active_count>1 {
        if active_count==2 {
            let mut pair=[0usize;2]; let mut found=0;
            for v in 0..n { if active[v] { pair[found]=v; found+=1; } }
            let (x,y)=(pair[0],pair[1]);
            let local=make_rake(&mut nodes,&mut count,&weights,base_rake[x],&branches[x],branch_count[x]);
            if local<0{return -1;}
            let branch=append(&mut nodes,&mut count,RAKE_BRANCH,&weights,edge_cluster[x][y],local,-1,y as i16,-1,x as i16,-1);
            if branch<0 || branch_count[y]>=N{return -1;} branches[y][branch_count[y]]=branch; branch_count[y]+=1;
            adj[x][y]=false; adj[y][x]=false; edge_cluster[x][y]=-1; edge_cluster[y][x]=-1; active[x]=false; active_count-=1; break;
        }
        let mut leaves=[0usize;N]; let mut leaf_neighbor=[0usize;N]; let mut leaf_count=0;
        for v in 0..n { if active[v] { let mut adjv=[0usize;2]; if neighbors(&adj,&active,n,v,&mut adjv)==1 { leaves[leaf_count]=v; leaf_neighbor[leaf_count]=adjv[0]; leaf_count+=1; } } }
        for i in 0..leaf_count {
            let (x,y)=(leaves[i],leaf_neighbor[i]);
            let local=make_rake(&mut nodes,&mut count,&weights,base_rake[x],&branches[x],branch_count[x]);
            if local<0{return -1;}
            let branch=append(&mut nodes,&mut count,RAKE_BRANCH,&weights,edge_cluster[x][y],local,-1,y as i16,-1,x as i16,-1);
            if branch<0 || branch_count[y]>=N{return -1;} branches[y][branch_count[y]]=branch; branch_count[y]+=1;
        }
        for i in 0..leaf_count { let (x,y)=(leaves[i],leaf_neighbor[i]); adj[x][y]=false; adj[y][x]=false; edge_cluster[x][y]=-1; edge_cluster[y][x]=-1; active[x]=false; active_count-=1; }
        if active_count<=1 { break; }
        let mut chosen=[false;N]; let mut cv=[0usize;N]; let mut cc=0;
        for x in 0..n { if active[x] { let mut a=[0usize;2]; if neighbors(&adj,&active,n,x,&mut a)!=2 {continue;} if !chosen[a[0]] && !chosen[a[1]] { chosen[x]=true; cv[cc]=x; cc+=1; } } }
        let mut px=[0usize;N]; let mut py=[0usize;N]; let mut pz=[0usize;N]; let mut pc=[-1i16;N];
        for i in 0..cc {
            let x=cv[i]; let mut a=[0usize;2]; neighbors(&adj,&active,n,x,&mut a); let (y,z)=(a[0],a[1]);
            let local=make_rake(&mut nodes,&mut count,&weights,base_rake[x],&branches[x],branch_count[x]); if local<0{return -1;}
            let c=append(&mut nodes,&mut count,COMPRESS,&weights,edge_cluster[y][x],edge_cluster[x][z],local,y as i16,z as i16,x as i16,-1); if c<0{return -1;}
            px[i]=x; py[i]=y; pz[i]=z; pc[i]=c;
        }
        for i in 0..cc { let (x,y,z)=(px[i],py[i],pz[i]); adj[y][x]=false;adj[x][y]=false;adj[x][z]=false;adj[z][x]=false;edge_cluster[y][x]=-1;edge_cluster[x][y]=-1;edge_cluster[x][z]=-1;edge_cluster[z][x]=-1;active[x]=false;active_count-=1; }
        for i in 0..cc { let (y,z)=(py[i],pz[i]); adj[y][z]=true;adj[z][y]=true;edge_cluster[y][z]=pc[i];edge_cluster[z][y]=pc[i]; }
    }
    let mut rv=0usize; while !active[rv] {rv+=1;}
    let root_cluster=make_rake(&mut nodes,&mut count,&weights,base_rake[rv],&branches[rv],branch_count[rv]); if root_cluster<0{return -1;}
    let mut staged=[0i64;Q]; let mut staged_count=0;
    for t in 0..q {
        if op_code[t]==0 {
            let e=op_edge[t]; weights[e]=op_value[t]; let mut id=base_edge[e] as usize; recalc(&mut nodes,id,&weights);
            let mut p=nodes[id].parent; while p>=0 {id=p as usize;recalc(&mut nodes,id,&weights);p=nodes[id].parent;}
        } else { staged[staged_count]=nodes[root_cluster as usize].diam;staged_count+=1; }
    }
    for i in 0..staged_count { store_le(output,8*i,staged[i]); }
    out_bytes as i64
}
