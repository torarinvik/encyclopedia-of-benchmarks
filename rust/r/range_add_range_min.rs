struct Tree { minimum:[i64;256], lazy:[i64;256] }
impl Tree {
    fn build(&mut self,values:&[i64],node:usize,l:usize,r:usize) {
        if r-l==1 { self.minimum[node]=values[l]; return; }
        let m=(l+r)/2;
        self.build(values,2*node,l,m); self.build(values,2*node+1,m,r);
        self.minimum[node]=self.minimum[2*node].min(self.minimum[2*node+1]);
    }
    fn push(&mut self,node:usize) {
        for child in [2*node,2*node+1] {
            self.minimum[child]+=self.lazy[node]; self.lazy[child]+=self.lazy[node];
        }
        self.lazy[node]=0;
    }
    fn add(&mut self,node:usize,l:usize,r:usize,ql:usize,qr:usize,delta:i64) {
        if qr<=l || r<=ql { return; }
        if ql<=l && r<=qr { self.minimum[node]+=delta; self.lazy[node]+=delta; return; }
        self.push(node); let m=(l+r)/2;
        self.add(2*node,l,m,ql,qr,delta); self.add(2*node+1,m,r,ql,qr,delta);
        self.minimum[node]=self.minimum[2*node].min(self.minimum[2*node+1]);
    }
    fn query(&mut self,node:usize,l:usize,r:usize,ql:usize,qr:usize)->i64 {
        if qr<=l || r<=ql { return i64::MAX; }
        if ql<=l && r<=qr { return self.minimum[node]; }
        self.push(node); let m=(l+r)/2;
        self.query(2*node,l,m,ql,qr).min(self.query(2*node+1,m,r,ql,qr))
    }
}
#[no_mangle]
pub unsafe extern "C" fn range_add_range_min(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64 {
    if input.is_null() || !(2..=322).contains(&length) { return -1; }
    let f=std::slice::from_raw_parts(input,length);
    if !(1..=64).contains(&f[0]) || !(1..=64).contains(&f[1]) { return -1; }
    let (n,q)=(f[0] as usize,f[1] as usize);
    if length!=2+n+4*q || f[2..2+n].iter().any(|&v| !(-1_000_000..=1_000_000).contains(&v)) { return -1; }
    let mut queries=0;
    for op in f[2+n..].chunks_exact(4) {
        if op[1]<0 || op[1]>=op[2] || op[2]>n as i64 { return -1; }
        match op[0] {
            0 if (-100_000..=100_000).contains(&op[3]) => (),
            1 if op[3]==0 => queries+=1,
            _ => return -1,
        }
    }
    if queries==0 { return -1; }
    if output.is_null() || capacity<8*queries { return -2; }
    let mut tree=Tree{minimum:[0;256],lazy:[0;256]};
    tree.build(&f[2..2+n],1,0,n);
    let mut written=0;
    for op in f[2+n..].chunks_exact(4) {
        let (l,r)=(op[1] as usize,op[2] as usize);
        if op[0]==0 { tree.add(1,0,n,l,r,op[3]); }
        else {
            let result=tree.query(1,0,n,l,r);
            std::ptr::copy_nonoverlapping(result.to_le_bytes().as_ptr(),output.add(8*written),8);
            written+=1;
        }
    }
    (8*written) as i64
}
