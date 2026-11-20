const N: usize = 64;
const Q: usize = 64;
const E: usize = 127;
const B: usize = 127;
const M: usize = 4;
const L: usize = 8;

fn shallower(a: usize, b: usize, depth: &[u16; E]) -> usize {
    if depth[a] < depth[b] || (depth[a] == depth[b] && a < b) { a } else { b }
}

fn rmq(a: usize, z: usize, ec: usize, bs: usize, depth: &[u16; E], pat: &[u8; B],
    micro: &[[[u8; M]; M]; 8], macro_table: &[[u16; B]; L], logs: &[u8; B + 1]) -> usize {
    let (ba, bz, oa, oz) = (a / bs, z / bs, a % bs, z % bs);
    if ba == bz { return ba * bs + micro[pat[ba] as usize][oa][oz] as usize; }
    let (xa, xz) = (ba * bs, bz * bs);
    let na = (ec - xa).min(bs);
    let mut best = xa + micro[pat[ba] as usize][oa][na - 1] as usize;
    best = shallower(best, xz + micro[pat[bz] as usize][0][oz] as usize, depth);
    if bz > ba + 1 {
        let (lo, hi) = (ba + 1, bz - 1);
        let k = logs[hi - lo + 1] as usize;
        let span = 1usize << k;
        best = shallower(best, macro_table[k][lo] as usize, depth);
        best = shallower(best, macro_table[k][hi - span + 1] as usize, depth);
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn rmq_cartesian_tree_fcb(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 195 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(1..=N as i64).contains(&input[0]) || !(0..=Q as i64).contains(&input[1]) { return -1; }
    let (n, q) = (input[0] as usize, input[1] as usize);
    let qo = 2 + n;
    if length != qo + 2*q { return -1; }
    let mut values = [0i64; N];
    for i in 0..n { values[i] = input[2+i]; if !(-1000..=1000).contains(&values[i]) { return -1; } }
    for i in 0..q { let a=input[qo+2*i]; let z=input[qo+2*i+1]; if a<0||a>z||z>=n as i64{return -1;} }
    if output.is_null() || output_capacity < q+1 { return -2; }

    let (mut left, mut right, mut parent, mut mono) = ([-1i32;N],[-1i32;N],[-1i32;N],[0usize;N]);
    let mut top=0usize;
    for i in 0..n { let mut last=-1i32; while top>0 && values[mono[top-1]]>values[i] {top-=1;last=mono[top] as i32;}
        if top>0 {let p=mono[top-1];right[p]=i as i32;parent[i]=p as i32;}
        if last>=0 {left[i]=last;parent[last as usize]=i as i32;}mono[top]=i;top+=1;}
    let root=(0..n).find(|&i|parent[i]<0).unwrap();
    let (mut euler,mut depth,mut first,mut node_depth)=([0u16;E],[0u16;E],[0usize;N],[0u16;N]);
    let (mut fnodes,mut states)=([0usize;N],[0u8;N]);
    let (mut ec,mut sp)=(1usize,1usize);euler[0]=root as u16;depth[0]=0;first[root]=0;node_depth[root]=0;fnodes[0]=root;
    while sp>0 {let slot=sp-1;let v=fnodes[slot];
        if states[slot]==0 {if left[v]>=0 {let c=left[v] as usize;states[slot]=1;node_depth[c]=node_depth[v]+1;first[c]=ec;euler[ec]=c as u16;depth[ec]=node_depth[c];ec+=1;fnodes[sp]=c;states[sp]=0;sp+=1;}
            else if right[v]>=0 {let c=right[v] as usize;states[slot]=2;node_depth[c]=node_depth[v]+1;first[c]=ec;euler[ec]=c as u16;depth[ec]=node_depth[c];ec+=1;fnodes[sp]=c;states[sp]=0;sp+=1;}else{sp-=1;}}
        else if states[slot]==1 {euler[ec]=v as u16;depth[ec]=node_depth[v];ec+=1;if right[v]>=0 {let c=right[v] as usize;states[slot]=2;node_depth[c]=node_depth[v]+1;first[c]=ec;euler[ec]=c as u16;depth[ec]=node_depth[c];ec+=1;fnodes[sp]=c;states[sp]=0;sp+=1;}else{sp-=1;}}
        else{euler[ec]=v as u16;depth[ec]=node_depth[v];ec+=1;sp-=1;}}

    let lg=(usize::BITS-1-ec.leading_zeros()) as usize;let bs=(lg/2).max(1);let blocks=(ec+bs-1)/bs;
    let(mut micro,mut pat,mut logs,mut macro_table)=([[[0u8;M];M];8],[0u8;B],[0u8;B+1],[[0u16;B];L]);
    for shape in 0..(1usize<<(bs-1)){let mut rel=[0i32;M];for j in 0..bs-1{rel[j+1]=rel[j]+if shape&(1<<j)!=0{1}else{-1};}
        for a in 0..bs{for z in a..bs{let mut best=a;for k in a+1..=z{if rel[k]<rel[best]{best=k;}}micro[shape][a][z]=best as u8;}}}
    for b in 0..blocks{let base=b*bs;let end=(base+bs).min(ec);let mut best=base;for j in base..end.saturating_sub(1){if depth[j+1]>depth[j]{pat[b]|=1<<(j-base);}best=shallower(best,j+1,&depth);}macro_table[0][b]=best as u16;}
    for c in 2..=blocks{logs[c]=logs[c/2]+1;}
    let mut k=1;while (1usize<<k)<=blocks&&k<L{let half=1usize<<(k-1);let span=2*half;for b in 0..=blocks.saturating_sub(span){macro_table[k][b]=shallower(macro_table[k-1][b] as usize,macro_table[k-1][b+half] as usize,&depth) as u16;}k+=1;}
    let mut answers=[0u8;Q];for i in 0..q{let a=first[input[qo+2*i] as usize];let z=first[input[qo+2*i+1] as usize];answers[i]=euler[rmq(a.min(z),a.max(z),ec,bs,&depth,&pat,&micro,&macro_table,&logs)] as u8;}
    let out=std::slice::from_raw_parts_mut(output,q+1);out[0]=q as u8;out[1..].copy_from_slice(&answers[..q]);(q+1) as i64
}
