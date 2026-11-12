use std::slice;

const N: usize = 16;
const Q: usize = 32;
const BASE: usize = 16;
const INPUT_MAX: usize = 5 * N + 4 * Q - 2;
const MOD: i64 = 998_244_353;
type Affine = (i64, i64);

fn compose(left: Affine, right: Affine) -> Affine {
    (left.0 * right.0 % MOD, (left.0 * right.1 + left.1) % MOD)
}
fn find(parent: &mut [usize; N], mut x: usize) -> usize {
    while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; }
    x
}
fn set_leaf(seg: &mut [Affine; 2 * BASE], pos: &[usize; N], mul: &[i64; N], add: &[i64; N], u: usize) {
    let mut k = BASE + pos[u]; seg[k] = (mul[u], add[u]);
    k /= 2;
    while k > 0 { seg[k] = compose(seg[2*k], seg[2*k+1]); k /= 2; }
}
fn chain_sum(seg: &[Affine; 2 * BASE], pos: &[usize; N], end: &[usize; N], h: usize) -> i64 {
    let (mut l, mut r) = (BASE + pos[h], BASE + end[h]);
    let (mut left, mut right) = ((1, 0), (1, 0));
    while l < r {
        if l & 1 == 1 { left = compose(left, seg[l]); l += 1; }
        if r & 1 == 1 { r -= 1; right = compose(seg[r], right); }
        l /= 2; r /= 2;
    }
    compose(left, right).1
}
fn store(out: *mut u8, at: usize, value: i64) {
    let bits = value as u64;
    for i in 0..8 { unsafe { out.add(at+i).write((bits >> (8*i)) as u8); } }
}

#[no_mangle]
pub unsafe extern "C" fn point_set_tree_path_composite_sum_fixed_root(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > INPUT_MAX { return -1; }
    let words = slice::from_raw_parts(input, length);
    let (nr, qr) = (words[0], words[1]);
    if nr < 1 || nr > N as i64 || qr < 1 || qr > Q as i64 { return -1; }
    let (n, q) = (nr as usize, qr as usize);
    let mut cur = 2;
    let mut value = [0i64; N];
    for x in value.iter_mut().take(n) {
        if cur >= length { return -1; }
        *x = words[cur]; cur += 1;
        if *x < 0 || *x >= MOD { return -1; }
    }
    let mut edge_at = [[-1i32; N]; N];
    let (mut eu, mut ev, mut eb, mut ec) = ([0usize; N-1], [0usize; N-1], [0i64; N-1], [0i64; N-1]);
    let (mut dsu, mut dsz) = ([0usize; N], [0usize; N]);
    for u in 0..n { dsu[u]=u; dsz[u]=1; }
    for e in 0..n-1 {
        if cur+4 > length { return -1; }
        let (ur,vr,b,c)=(words[cur],words[cur+1],words[cur+2],words[cur+3]); cur+=4;
        if ur<0||ur>=nr||vr<0||vr>=nr||ur==vr||b<1||b>=MOD||c<0||c>=MOD{return -1;}
        let (u,v)=(ur as usize,vr as usize);
        let (mut ru,mut rv)=(find(&mut dsu,u),find(&mut dsu,v));
        if ru==rv{return -1;} if dsz[ru]<dsz[rv]{std::mem::swap(&mut ru,&mut rv);}
        dsu[rv]=ru;dsz[ru]+=dsz[rv];eu[e]=u;ev[e]=v;eb[e]=b;ec[e]=c;edge_at[u][v]=e as i32;edge_at[v][u]=e as i32;
    }
    let mut ops=[(0i64,0i64,0i64,0i64);Q];
    for op in ops.iter_mut().take(q) {
        if cur>=length{return -1;} let kind=words[cur];cur+=1;
        if kind==0 {
            if cur+2>length{return -1;} let (x,y)=(words[cur],words[cur+1]);cur+=2;
            if x<0||x>=nr||y<0||y>=MOD{return -1;} *op=(kind,x,y,0);
        } else if kind==1 {
            if cur+3>length{return -1;} let (x,y,z)=(words[cur],words[cur+1],words[cur+2]);cur+=3;
            if x<0||x>=nr-1||y<1||y>=MOD||z<0||z>=MOD{return -1;} *op=(kind,x,y,z);
        } else{return -1;}
    }
    if cur!=length{return -1;}
    let bytes=8*q; if output.is_null()||capacity<bytes{return -2;}

    let (mut parent,mut pedge,mut depth)=([-2i64;N],[-1i64;N],[0i64;N]);
    let (mut order,mut stack) = ([0usize;N],[0usize;N]); let (mut count,mut top)=(0,0);
    parent[0]=-1;stack[top]=0;top+=1;
    while top>0 {top-=1;let u=stack[top];order[count]=u;count+=1;
        for v in 0..n {if edge_at[u][v]>=0&&v as i64!=parent[u]{parent[v]=u as i64;pedge[v]=edge_at[u][v] as i64;depth[v]=depth[u]+1;stack[top]=v;top+=1;}}
    }
    let (mut sub,mut heavy)=([1usize;N],[-1i64;N]);
    for i in (0..count).rev(){let u=order[i];let mut best=0;
        for v in 0..n {if parent[v]==u as i64{sub[u]+=sub[v];if sub[v]>best||(sub[v]==best&&(heavy[u]<0||v<heavy[u] as usize)){best=sub[v];heavy[u]=v as i64;}}}
    }
    let (mut head,mut pos,mut end,mut heads)=([0usize;N],[0usize;N],[0usize;N],[0usize;N]);
    let mut timer=0;top=0;heads[top]=0;top+=1;
    while top>0 {top-=1;let h=heads[top];let mut u=h;
        loop {head[u]=h;pos[u]=timer;timer+=1;
            for v in 0..n {if parent[v]==u as i64&&heavy[u]!=v as i64{heads[top]=v;top+=1;}}
            if heavy[u]<0{break;}u=heavy[u] as usize;
        } end[h]=timer;
    }
    let mut down=[0i64;N];
    for i in (0..count).rev(){let u=order[i];let mut s=value[u];for v in 0..n{if parent[v]==u as i64{let e=pedge[v] as usize;s+=eb[e]*down[v]+ec[e]*sub[v] as i64;}}down[u]=s%MOD;}
    let (mut mul,mut add)=([0i64;N],[0i64;N]);
    for u in 0..n {add[u]=value[u];for v in 0..n{if parent[v]==u as i64{let e=pedge[v] as usize;if heavy[u]==v as i64{mul[u]=eb[e];add[u]+=ec[e]*sub[v] as i64;}else{add[u]+=eb[e]*down[v]+ec[e]*sub[v] as i64;}}}add[u]%=MOD;}
    let mut seg=[(1i64,0i64);2*BASE];
    for u in 0..n{seg[BASE+pos[u]]=(mul[u],add[u]);}
    for i in (1..BASE).rev(){seg[i]=compose(seg[2*i],seg[2*i+1]);}
    let mut current=[0i64;N];for u in 0..n{if head[u]==u{current[u]=down[u];}}
    for (qi,(kind,x,y,z)) in ops.iter().take(q).copied().enumerate(){
        let start:usize;
        if kind==0 {let u=x as usize;add[u]=(add[u]+y-value[u])%MOD;if add[u]<0{add[u]+=MOD;}value[u]=y;set_leaf(&mut seg,&pos,&mul,&add,u);start=u;}
        else {let e=x as usize;let (u,v)=(eu[e],ev[e]);let child=if parent[u]==v as i64{u}else{v};let p=parent[child] as usize;let (ob,oc)=(eb[e],ec[e]);
            if heavy[p]==child as i64{mul[p]=y;add[p]=(add[p]+(z-oc)*sub[child] as i64)%MOD;}
            else{add[p]=(add[p]+(y-ob)*current[child]+(z-oc)*sub[child] as i64)%MOD;}
            if add[p]<0{add[p]+=MOD;}eb[e]=y;ec[e]=z;set_leaf(&mut seg,&pos,&mul,&add,p);start=p;
        }
        let mut u=start;
        loop {let h=head[u];let old=current[h];current[h]=chain_sum(&seg,&pos,&end,h);if h==0{break;}let p=parent[h] as usize;let e=pedge[h] as usize;add[p]=(add[p]+eb[e]*(current[h]-old))%MOD;if add[p]<0{add[p]+=MOD;}set_leaf(&mut seg,&pos,&mul,&add,p);u=p;}
        store(output,8*qi,current[0]);
    }
    bytes as i64
}
