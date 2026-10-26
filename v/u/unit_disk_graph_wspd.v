module unit_disk_graph_wspd
const max_n=8
const max_pairs=28
const max_input=18
const max_output=456
const inf=i64(2305843009213693951)
struct Context { n int; c int; count int; distance [max_n][max_n]i64; left [max_pairs]u64; right [max_pairs]u64 }
fn bit_count(mask0 u64) int { mut mask:=mask0; mut count:=0; for mask!=0 { count+=int(mask&1); mask>>=1 }; return count }
fn split_mask(mask u64) (u64,u64) { mut left:=u64(0); mut right:=u64(0); half:=bit_count(mask)/2; mut seen:=0; for i in 0..max_n { if mask&(u64(1)<<u32(i))!=0 { if seen<half { left|=u64(1)<<u32(i) } else { right|=u64(1)<<u32(i) }; seen++ } }; return left,right }
fn diameter(x &Context,mask u64) i64 { mut best:=i64(0); for i in 0..x.n { if mask&(u64(1)<<u32(i))!=0 { for j in i+1..x.n { if mask&(u64(1)<<u32(j))!=0&&x.distance[i][j]>best { best=x.distance[i][j] } } } }; return best }
fn set_distance(x &Context,a u64,b u64) i64 { mut best:=inf; for i in 0..x.n { if a&(u64(1)<<u32(i))!=0 { for j in 0..x.n { if b&(u64(1)<<u32(j))!=0&&x.distance[i][j]<best { best=x.distance[i][j] } } } }; return best }
fn cross(mut x &Context,a u64,b u64) { da:=diameter(x,a); db:=diameter(x,b); maxd:=if da>db { da } else { db }; if set_distance(x,a,b)>=i64(x.c)*maxd { if x.count<max_pairs { x.left[x.count]=a; x.right[x.count]=b; x.count++ }; return }; if bit_count(a)>=bit_count(b)&&bit_count(a)>1 { left,right:=split_mask(a); cross(mut x,left,b); cross(mut x,right,b) } else { left,right:=split_mask(b); cross(mut x,a,left); cross(mut x,a,right) } }
fn visit(mut x &Context,mask u64) { if bit_count(mask)<2 { return }; left,right:=split_mask(mask); visit(mut x,left); visit(mut x,right); cross(mut x,left,right) }
fn put_i64(mut out &u8,at int,value i64) { bits:=u64(value); for i in 0..8 { unsafe { out[at+i]=u8((bits>>(8*i))&255) } } }
@[export:'unit_disk_graph_wspd']
pub fn unit_disk_graph_wspd(input &i64,length usize,mut output &u8,capacity usize)i64 { unsafe {
 if input==nil||length<4||length>max_input { return -1 }; n64,c64:=input[0],input[1]; if n64<1||n64>max_n||c64<1||c64>8||length!=usize(2+2*n64) { return -1 }; n:=int(n64)
 mut px:=[max_n]i64{}; mut py:=[max_n]i64{}
 for i in 0..n { px[i]=input[2+2*i]; py[i]=input[3+2*i]; if px[i] < -8||px[i]>8||py[i] < -8||py[i]>8 { return -1 }; for j in 0..i { if px[i]==px[j]&&py[i]==py[j] { return -1 } } }
 mut x:=Context{n:n,c:int(c64)}
 for i in 0..n { for j in 0..n { x.distance[i][j]=if i==j { 0 } else { inf } } }
 for i in 0..n { for j in i+1..n { dx:=px[i]-px[j]; dy:=py[i]-py[j]; if dx*dx+dy*dy<=1 { x.distance[i][j]=1; x.distance[j][i]=1 } } }
 for k in 0..n { for i in 0..n { for j in 0..n { alt:=x.distance[i][k]+x.distance[k][j]; if alt<x.distance[i][j] { x.distance[i][j]=alt } } } }
 for i in 0..n { for j in 0..n { if x.distance[i][j]>=inf/2 { return -1 } } }
 visit(mut x,(u64(1)<<u32(n))-1); bytes:=8+16*x.count; if output==nil||capacity<bytes { return -2 }; mut staged:=[max_output]u8{}; put_i64(mut &staged[0],0,i64(x.count)); for i in 0..x.count { put_i64(mut &staged[0],8+16*i,i64(x.left[i])); put_i64(mut &staged[0],16+16*i,i64(x.right[i])) }; for i in 0..bytes { output[i]=staged[i] }; return i64(bytes)
} }
