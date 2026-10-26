const N: usize = 8;
const PAIRS: usize = 28;
const INF: i64 = i64::MAX / 4;

struct Context { n: usize, c: i64, d: [[i64; N]; N], pairs: [(u64, u64); PAIRS], count: usize }
fn bits(mut mask: u64) -> usize { let mut n=0; while mask!=0 { n+=(mask&1) as usize; mask>>=1; } n }
fn split(mask:u64)->(u64,u64){let half=bits(mask)/2;let(mut a,mut b,mut seen)=(0u64,0u64,0usize);for i in 0..N{if mask&(1u64<<i)!=0{if seen<half{a|=1u64<<i}else{b|=1u64<<i}seen+=1}}(a,b)}
fn diameter(x:&Context,mask:u64)->i64{let mut best=0;for i in 0..x.n{if mask&(1u64<<i)!=0{for j in i+1..x.n{if mask&(1u64<<j)!=0&&x.d[i][j]>best{best=x.d[i][j]}}}}best}
fn set_distance(x:&Context,a:u64,b:u64)->i64{let mut best=INF;for i in 0..x.n{if a&(1u64<<i)!=0{for j in 0..x.n{if b&(1u64<<j)!=0&&x.d[i][j]<best{best=x.d[i][j]}}}}best}
fn cross(x:&mut Context,a:u64,b:u64){let da=diameter(x,a);let db=diameter(x,b);if set_distance(x,a,b)>=x.c*da.max(db){if x.count<PAIRS{x.pairs[x.count]=(a,b);x.count+=1}return}if bits(a)>=bits(b)&&bits(a)>1{let(l,r)=split(a);cross(x,l,b);cross(x,r,b)}else{let(l,r)=split(b);cross(x,a,l);cross(x,a,r)}}
fn visit(x:&mut Context,mask:u64){if bits(mask)<2{return}let(l,r)=split(mask);visit(x,l);visit(x,r);cross(x,l,r)}
fn put_i64(out:&mut[u8],offset:usize,value:i64){out[offset..offset+8].copy_from_slice(&value.to_le_bytes())}

#[no_mangle]
pub unsafe extern "C" fn unit_disk_graph_wspd(v:*const i64,length:usize,out:*mut u8,capacity:usize)->i64{
 if v.is_null()||length<4||length>18{return -1}let n0=*v;let c=*v.add(1);if !(1..=8).contains(&n0)||!(1..=8).contains(&c)||length!=2+2*n0 as usize{return -1}let n=n0 as usize;let mut xcoord=[0i64;N];let mut ycoord=[0i64;N];
 for i in 0..n{xcoord[i]=*v.add(2+2*i);ycoord[i]=*v.add(3+2*i);if !(-8..=8).contains(&xcoord[i])||!(-8..=8).contains(&ycoord[i]){return -1}for j in 0..i{if xcoord[i]==xcoord[j]&&ycoord[i]==ycoord[j]{return -1}}}
 let mut d=[[INF;N];N];for i in 0..n{d[i][i]=0}for i in 0..n{for j in i+1..n{let dx=xcoord[i]-xcoord[j];let dy=ycoord[i]-ycoord[j];if dx*dx+dy*dy<=1{d[i][j]=1;d[j][i]=1}}}
 for k in 0..n{for i in 0..n{for j in 0..n{let alt=d[i][k]+d[k][j];if alt<d[i][j]{d[i][j]=alt}}}}for i in 0..n{for j in 0..n{if d[i][j]>=INF/2{return -1}}}
 let mut x=Context{n,c,d,pairs:[(0,0);PAIRS],count:0};visit(&mut x,(1u64<<n)-1);let bytes=8+16*x.count;if out.is_null()||capacity<bytes{return -2}let mut stage=[0u8;456];put_i64(&mut stage,0,x.count as i64);for i in 0..x.count{put_i64(&mut stage,8+16*i,x.pairs[i].0 as i64);put_i64(&mut stage,16+16*i,x.pairs[i].1 as i64)}std::ptr::copy_nonoverlapping(stage.as_ptr(),out,bytes);bytes as i64
}
