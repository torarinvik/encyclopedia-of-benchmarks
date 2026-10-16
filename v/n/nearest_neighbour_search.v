fn node_base(d int, i int) int { return 2+d+i*(d+2) }
fn validate_tree(v &i64,d int,n int,i int,mut seen [15]bool,mut reached int) bool {
 if i<0{return true};if i>=n||seen[i]{return false};seen[i]=true;reached++;b:=node_base(d,i);l:=int(v[b+d]);r:=int(v[b+d+1]);if l>=0&&l==r{return false};return validate_tree(v,d,n,l,mut seen,mut reached)&&validate_tree(v,d,n,r,mut seen,mut reached)
}
fn search_tree(v &i64,d int,i int,depth int,q [3]i64,mut best [3]i64,mut bestd i64,mut visited i64) {
 if i<0{return};visited++;b:=node_base(d,i);mut dist:=i64(0);for k in 0..d{delta:=q[k]-unsafe{v[b+k]};dist+=delta*delta};if dist<bestd{bestd=dist;for k in 0..d{best[k]=unsafe{v[b+k]}}};axis:=depth%d;l:=int(unsafe{v[b+d]});r:=int(unsafe{v[b+d+1]});mut near:=l;mut far:=r;if q[axis]>unsafe{v[b+axis]}{near=r;far=l};search_tree(v,d,near,depth+1,q,mut best,mut bestd,mut visited);split:=q[axis]-unsafe{v[b+axis]};if split*split<bestd{search_tree(v,d,far,depth+1,q,mut best,mut bestd,mut visited)}
}
fn put_i64(mut outp &u8,offset int,x i64){mut bits:=u64(x);for k in 0..8{unsafe{outp[offset+k]=u8(bits&255)};bits>>=8}}
@[export: 'nearest_neighbour_search']
pub fn nearest_neighbour_search(v &i64,n usize,outp &u8,cap usize)i64{
 if n<5{return -1};d0:=unsafe{v[0]};n0:=unsafe{v[1]};if(d0!=2&&d0!=3)||n0<1||n0>15{return -1};d:=int(d0);count:=int(n0);if n!=usize(2+d+count*(d+2)){return -1};mut q:=[3]i64{};mut best:=[3]i64{}
 for k in 0..d{q[k]=unsafe{v[2+k]};if q[k]< -1000||q[k]>1000{return -1}}
 for i in 0..count{b:=node_base(d,i);for k in 0..d{x:=unsafe{v[b+k]};if x < -1000||x>1000{return -1}};l:=unsafe{v[b+d]};r:=unsafe{v[b+d+1]};if l < -1||l>=n0||r < -1||r>=n0||(l>=0&&l==r){return -1}}
 mut seen:=[15]bool{};mut reached:=0;if !validate_tree(v,d,count,0,mut seen,mut reached)||reached!=count{return -1};mut bestd:=i64(9223372036854775807);mut visited:=i64(0);search_tree(v,d,0,0,q,mut best,mut bestd,mut visited);if cap<48||isnil(outp){return -2};mut result:=[6]i64{d0,best[0],best[1],0,bestd,visited};if d==3{result[3]=best[2]};for k in 0..6{put_i64(mut outp,k*8,result[k])};return 48
}
