const N: usize = 32;
const M: usize = 96;
const D: usize = 192;
#[derive(Clone, Copy)]
struct Interval { low: i32, high: i32 }
#[derive(Clone, Copy)]
struct Conflict { left: Interval, right: Interval }
impl Interval { fn empty(self)->bool { self.low < 0 } }
impl Conflict {
    fn empty()->Self { Self { left: Interval{low:-1,high:-1}, right: Interval{low:-1,high:-1} } }
    fn swap(&mut self) { std::mem::swap(&mut self.left,&mut self.right); }
}
struct State {
    n: usize,m: usize,edge_of:[[i32;N];N],adj:[[i32;N];N],degree:[usize;N],
    eu:[i32;M],ev:[i32;M],tail:[i32;M],head:[i32;M],height:[i32;N],parent:[i32;N],
    low:[i32;M],low2:[i32;M],nest:[i32;M],out:[[i32;N];N],out_count:[usize;N],
    reference:[i32;M],side:[i32;M],low_edge:[i32;M],bottom:[i32;M],
    stack:[Conflict;D],stack_len:usize,rotation:[[i32;N];N],rotation_count:[usize;N],
    left_ref:[i32;N],right_ref:[i32;N],roots:[i32;N],root_count:usize,
}
impl State {
    fn new(n:usize,m:usize)->Self { Self {
        n,m,edge_of:[[-1;N];N],adj:[[0;N];N],degree:[0;N],eu:[0;M],ev:[0;M],
        tail:[-1;M],head:[-1;M],height:[-1;N],parent:[-1;N],low:[0;M],low2:[0;M],nest:[0;M],
        out:[[0;N];N],out_count:[0;N],reference:[-1;M],side:[1;M],low_edge:[-1;M],bottom:[-1;M],
        stack:[Conflict::empty();D],stack_len:0,rotation:[[0;N];N],rotation_count:[0;N],
        left_ref:[-1;N],right_ref:[-1;N],roots:[0;N],root_count:0,
    } }
    fn update_parent(&mut self,b:i32,pe:i32) {
        if pe<0{return} let (b,p)=(b as usize,pe as usize);
        if self.low[b]<self.low[p] { self.low2[p]=self.low[p].min(self.low2[b]); self.low[p]=self.low[b]; }
        else if self.low[b]>self.low[p] { self.low2[p]=self.low2[p].min(self.low[b]); }
        else { self.low2[p]=self.low2[p].min(self.low2[b]); }
    }
    fn orient(&mut self,v:usize) {
        let pe=self.parent[v];
        for i in 0..self.degree[v] {
            let w=self.adj[v][i] as usize; let e=self.edge_of[v][w] as usize;
            if self.tail[e]>=0 {continue}
            self.tail[e]=v as i32; self.head[e]=w as i32; self.low[e]=self.height[v]; self.low2[e]=self.height[v];
            if self.height[w]<0 {
                self.parent[w]=e as i32; self.height[w]=self.height[v]+1; self.orient(w);
                self.nest[e]=2*self.low[e]+if self.low2[e]<self.height[v]{1}else{0};
            } else {
                self.low[e]=self.height[w]; self.low2[e]=self.height[v];
                self.nest[e]=2*self.low[e]+if self.low2[e]<self.height[v]{1}else{0};
            }
            self.update_parent(e as i32,pe);
        }
    }
    fn interval_conflicts(&self,a:Interval,e:usize)->bool { a.high>=0 && self.low[a.high as usize]>self.low[e] }
    fn pair_lowest(&self,p:Conflict)->i32 {
        let a=if p.left.low>=0 {self.low[p.left.low as usize]} else {1000};
        let b=if p.right.low>=0 {self.low[p.right.low as usize]} else {1000}; a.min(b)
    }
    fn add_constraints(&mut self,ei:usize,pe:usize)->bool {
        let mut p=Conflict::empty();
        loop {
            if self.stack_len==0{return false}
            self.stack_len-=1; let mut q=self.stack[self.stack_len];
            if !q.left.empty(){q.swap()} if !q.left.empty(){return false}
            if self.low[q.right.low as usize]>self.low[pe] {
                if p.right.empty(){p.right=q.right} else {self.reference[p.right.low as usize]=q.right.high;p.right.low=q.right.low}
            } else {self.reference[q.right.low as usize]=self.low_edge[pe]}
            if self.stack_len as i32-1==self.bottom[ei]{break}
        }
        while self.stack_len>0 && (self.interval_conflicts(self.stack[self.stack_len-1].left,ei)||self.interval_conflicts(self.stack[self.stack_len-1].right,ei)) {
            self.stack_len-=1; let mut q=self.stack[self.stack_len];
            if self.interval_conflicts(q.right,ei){q.swap()} if self.interval_conflicts(q.right,ei){return false}
            if p.right.low>=0 {self.reference[p.right.low as usize]=q.right.high}
            if q.right.low>=0 {p.right.low=q.right.low}
            if p.left.empty(){p.left=q.left} else {self.reference[p.left.low as usize]=q.left.high;p.left.low=q.left.low}
        }
        if !p.left.empty()||!p.right.empty(){self.stack[self.stack_len]=p;self.stack_len+=1} true
    }
    fn remove_returns(&mut self,e:usize) {
        let u=self.tail[e] as usize;
        while self.stack_len>0 && self.pair_lowest(self.stack[self.stack_len-1])==self.height[u] {
            self.stack_len-=1; let p=self.stack[self.stack_len]; if p.left.low>=0 {self.side[p.left.low as usize]=-1}
        }
        if self.stack_len>0 {
            self.stack_len-=1; let mut p=self.stack[self.stack_len];
            while p.left.high>=0 && self.head[p.left.high as usize]==u as i32 {p.left.high=self.reference[p.left.high as usize]}
            if p.left.high<0&&p.left.low>=0 {self.reference[p.left.low as usize]=p.right.low;self.side[p.left.low as usize]=-1;p.left.low=-1}
            while p.right.high>=0&&self.head[p.right.high as usize]==u as i32 {p.right.high=self.reference[p.right.high as usize]}
            if p.right.high<0&&p.right.low>=0 {self.reference[p.right.low as usize]=p.left.low;self.side[p.right.low as usize]=-1;p.right.low=-1}
            self.stack[self.stack_len]=p;self.stack_len+=1;
        }
        if self.low[e]<self.height[u]&&self.stack_len>0 {
            let p=self.stack[self.stack_len-1];let (lh,rh)=(p.left.high,p.right.high);
            self.reference[e]=if lh>=0&&(rh<0||self.low[lh as usize]>self.low[rh as usize]){lh}else{rh};
        }
    }
    fn test(&mut self,v:usize)->bool {
        let pe=self.parent[v];
        for i in 0..self.out_count[v] {
            let e=self.out[v][i] as usize;let w=self.head[e] as usize;self.bottom[e]=self.stack_len as i32-1;
            if self.parent[w]==e as i32 {if !self.test(w){return false}}
            else {
                self.low_edge[e]=e as i32;let mut p=Conflict::empty();p.right=Interval{low:e as i32,high:e as i32};
                self.stack[self.stack_len]=p;self.stack_len+=1;
                if self.low[e]<self.height[v] {
                    if i==0 {if pe>=0{self.low_edge[pe as usize]=self.low_edge[e]}}
                    else if pe<0||!self.add_constraints(e,pe as usize){return false}
                }
            }
        }
        if pe>=0{self.remove_returns(pe as usize)} true
    }
    fn resolve_side(&mut self,e:usize)->i32 {
        if self.reference[e]>=0 {let r=self.reference[e] as usize;let sign=self.resolve_side(r);self.side[e]*=sign;self.reference[e]=-1}
        self.side[e]
    }
    fn edge_before(&self,a:i32,b:i32,depth:&[i32;M])->bool {
        depth[a as usize]<depth[b as usize]||(depth[a as usize]==depth[b as usize]&&self.head[a as usize]<self.head[b as usize])
    }
    fn insert(&mut self,v:usize,w:i32,reference:i32,after:bool) {
        let count=self.rotation_count[v];let mut pos=0;
        if count>0&&reference>=0 {while pos<count&&self.rotation[v][pos]!=reference{pos+=1}if pos==count{pos=count}else if after{pos=(pos+1)%count}}
        for i in (pos..count).rev(){self.rotation[v][i+1]=self.rotation[v][i]}
        self.rotation[v][pos]=w;self.rotation_count[v]=count+1;
    }
    fn embed(&mut self,v:usize) {
        for i in 0..self.out_count[v] {
            let e=self.out[v][i] as usize;let w=self.head[e] as usize;
            if self.parent[w]==e as i32 {self.insert(w,v as i32,-1,false);self.left_ref[v]=w as i32;self.right_ref[v]=w as i32;self.embed(w)}
            else if self.side[e]==1 {let r=self.right_ref[w];self.insert(w,v as i32,r,true)}
            else {let r=self.left_ref[w];self.insert(w,v as i32,r,false);self.left_ref[w]=v as i32}
        }
    }
}

fn run(frame:&[i64],output:*mut u8,capacity:usize)->i64 {
    if frame.len()<2||frame.len()>195{return -1}let n64=frame[0];let m64=frame[1];
    if !(1..=32).contains(&n64)||!(0..=96).contains(&m64)||frame.len()!=2+2*m64 as usize{return -1}
    let (n,m)=(n64 as usize,m64 as usize);let mut s=State::new(n,m);
    for e in 0..m {let u=frame[2+2*e];let v=frame[3+2*e];if u<0||u>=v||v>=n64{return -1}let (u,v)=(u as usize,v as usize);if s.edge_of[u][v]>=0{return -1}s.edge_of[u][v]=e as i32;s.edge_of[v][u]=e as i32;s.eu[e]=u as i32;s.ev[e]=v as i32;}
    for v in 0..n {for w in 0..n {if s.edge_of[v][w]>=0{let i=s.degree[v];s.adj[v][i]=w as i32;s.degree[v]+=1}}}
    for root in 0..n {if s.height[root]<0{s.height[root]=0;s.roots[s.root_count]=root as i32;s.root_count+=1;s.orient(root)}}
    for e in 0..m {let v=s.tail[e] as usize;let i=s.out_count[v];s.out[v][i]=e as i32;s.out_count[v]+=1}
    for v in 0..n {for i in 1..s.out_count[v] {let e=s.out[v][i];let mut j=i;while j>0&&s.edge_before(e,s.out[v][j-1],&s.nest){s.out[v][j]=s.out[v][j-1];j-=1}s.out[v][j]=e}}
    let mut planar=true;for i in 0..s.root_count{if !s.test(s.roots[i] as usize){planar=false;break}}
    if output.is_null(){return -2}unsafe{if !planar{if capacity<1{return -2}*output=0;return 1}}
    let mut depth=[0i32;M];for e in 0..m{depth[e]=s.nest[e]*s.resolve_side(e)}
    for v in 0..n{for i in 1..s.out_count[v]{let e=s.out[v][i];let mut j=i;while j>0&&s.edge_before(e,s.out[v][j-1],&depth){s.out[v][j]=s.out[v][j-1];j-=1}s.out[v][j]=e}}
    for v in 0..n{for i in 0..s.out_count[v]{let j=s.rotation_count[v];s.rotation[v][j]=s.head[s.out[v][i] as usize];s.rotation_count[v]+=1}}
    for i in 0..s.root_count{s.embed(s.roots[i] as usize)}
    let needed=1+2*m;if capacity<needed{return -2}unsafe{*output=1;let mut at=1;for v in 0..n{for i in 0..s.rotation_count[v]{*output.add(at)=s.rotation[v][i] as u8;at+=1}}}needed as i64
}

#[no_mangle]
pub unsafe extern "C" fn planar_embedding_lr(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null()||length>195{return -1}
    let frame=std::slice::from_raw_parts(input,length);
    run(frame,output,capacity)
}
