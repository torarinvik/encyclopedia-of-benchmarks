const dr=[8]int{1,-1,1,-1,2,2,-2,-2}
const dc=[8]int{2,2,-2,-2,1,-1,1,-1}
fn search(mut b [25]int,n int,r int,c int,step int) bool {if step==n*n{return true};for k in 0..8{nr:=r+dr[k];nc:=c+dc[k];if nr>=0&&nr<n&&nc>=0&&nc<n{at:=nr*n+nc;if b[at]==0{b[at]=step+1;if search(mut b,n,nr,nc,step+1){return true};b[at]=0}}};return false}
fn put(mut outp &u8,off int,x int){mut bits:=u32(x);for k in 0..4{unsafe{outp[off+k]=u8(bits&255)};bits>>=8}}
@[export:'open_knight_tour']
pub fn open_knight_tour(v &i64,n usize,outp &u8,cap usize)i64{if n!=1||isnil(v){return -1};d:=int(unsafe{v[0]});if d!=1&&d!=5{return -1};bytes:=d*d*4;if cap<bytes||isnil(outp){return -2};mut b:=[25]int{};mut found:=false;for r in 0..d{for c in 0..d{b[r*d+c]=1;if search(mut b,d,r,c,1){found=true;break};b[r*d+c]=0};if found{break}};for i in 0..d*d{put(mut outp,i*4,b[i])};return i64(bytes)}
