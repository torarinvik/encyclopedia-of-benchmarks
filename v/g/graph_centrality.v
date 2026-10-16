module graph_centrality
fn put64(out &u8, at int, value i64) { bits := u64(value); for b in 0 .. 8 { unsafe { out[at*8+b] = u8(bits >> (b*8)) } } }
@[export: 'graph_centrality']
pub fn graph_centrality(input &i64, length usize, output &u8, capacity usize) i64 {
 unsafe {
 if isnil(input) || length < 2 { return -1 }
 nn, ee := unsafe { input[0] }, unsafe { input[1] }
 if nn < 1 || nn > 16 || ee < 0 || ee > nn*(nn-1) || length != usize(2+3*ee) { return -1 }
 mut d := [16][16]i64{}
 for i in 0 .. int(nn) { for j in 0 .. int(nn) { d[i][j] = if i == j { 0 } else { i64(0x7fffffffffffffff) } } }
 for z in 0 .. int(ee) { a:=unsafe{input[2+3*z]}; b:=unsafe{input[3+3*z]}; w:=unsafe{input[4+3*z]}; if a<0||a>=nn||b<0||b>=nn||a==b||w<1||w>1000000||d[a][b]!=i64(0x7fffffffffffffff){return -1};d[a][b]=w }
 for k in 0 .. int(nn) { for i in 0 .. int(nn) { if d[i][k] == i64(0x7fffffffffffffff) { continue }; for j in 0 .. int(nn) { if d[k][j] != i64(0x7fffffffffffffff) && d[i][k]+d[k][j]<d[i][j] { d[i][j]=d[i][k]+d[k][j] } } } }
 mut c:=i64(-1);mut m:=i64(-1);mut be:=i64(0x7fffffffffffffff);mut bh:=f64(-1)
 if nn==1 { c=0;m=0 } else { for i in 0 .. int(nn) { mut reachable:=false;mut ec:=i64(0);mut h:=f64(0);for j in 0 .. int(nn) { if i!=j&&d[i][j]!=i64(0x7fffffffffffffff){reachable=true;if d[i][j]>ec{ec=d[i][j]};h+=1.0/f64(d[i][j])} };if reachable&&ec<be{be=ec;c=i64(i)};if reachable&&h>bh{bh=h;m=i64(i)} } }
 if isnil(output)||capacity<16{return -2};put64(output,0,c);put64(output,1,m);return 16
 }
}
