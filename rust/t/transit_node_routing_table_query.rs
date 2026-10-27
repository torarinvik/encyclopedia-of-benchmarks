use std::slice;

fn put(out: &mut [u8], word: usize, x: i64) { out[word*8..word*8+8].copy_from_slice(&x.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn transit_node_routing_table_query(input:*const i64,length:usize,
    output:*mut u8,capacity:usize)->i64 {
    if input.is_null()||length<11||length>86{return -1;}
    let a=slice::from_raw_parts(input,length);let q0=a[0];let source=a[1];let target=a[2];
    if !(1..=8).contains(&q0)||!(0..32).contains(&source)||!(0..32).contains(&target)||a[3]!=1{return -1;}
    let q=q0 as usize;let mut at=4usize;let nf0=a[at];at+=1;
    if nf0<1||nf0>4||nf0>q0||at+2*nf0 as usize>length{return -1;}
    let nf=nf0 as usize;let mut f=[0usize;8];let mut ds=[0i64;8];
    for i in 0..nf{let u=a[at];let d=a[at+1];at+=2;if u<0||u>=q0||d<0||d>1_000_000||f[..i].contains(&(u as usize)){return -1;}f[i]=u as usize;ds[i]=d;}
    if at>=length{return -1;}let nb0=a[at];at+=1;if nb0<1||nb0>4||nb0>q0||at+2*nb0 as usize>length{return -1;}
    let nb=nb0 as usize;let mut b=[0usize;8];let mut dt=[0i64;8];
    for i in 0..nb{let v=a[at];let d=a[at+1];at+=2;if v<0||v>=q0||d<0||d>1_000_000||b[..i].contains(&(v as usize)){return -1;}b[i]=v as usize;dt[i]=d;}
    if at+q*q!=length{return -1;}let mut table=[[0i64;8];8];
    for i in 0..q{for j in 0..q{let d=a[at];at+=1;if d<0||d>1_000_000{return -1;}table[i][j]=d;}}
    for i in 0..q{if table[i][i]!=0{return -1;}}
    let mut best=i64::MAX;let(mut bestu,mut bestv)=(0usize,0usize);
    for i in 0..nf{for j in 0..nb{let d=ds[i]+table[f[i]][b[j]]+dt[j];if d<best||(d==best&&(f[i]<bestu||(f[i]==bestu&&b[j]<bestv))){best=d;bestu=f[i];bestv=b[j];}}}
    if output.is_null()||capacity<24{return -2;}let out=slice::from_raw_parts_mut(output,24);put(out,0,best);put(out,1,bestu as i64);put(out,2,bestv as i64);24
}
