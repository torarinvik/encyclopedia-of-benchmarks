const offset=u64(0xcbf29ce484222325)
const prime=u64(0x100000001b3)
fn feed(mut h u64,v i64)u64{mut bits:=u64(v);for _ in 0..8{h=(h^u64(u8(bits&255)))*prime;bits>>=8};return h}
@[export: 'pareto_optimization']
pub fn pareto_optimization(a &i64,len usize)i64{if unsafe{a==nil}||len<2||len>514{return -1};r64:=unsafe{a[0]};c64:=unsafe{a[1]};if r64<1||r64>64||c64<1||c64>8||len!=usize(2+r64*c64){return -1};r:=int(r64);c:=int(c64);for k in 0..r*c{v:=unsafe{a[2+k]};if v< -1000||v>1000{return -1}};mut keep:=[64]bool{};mut kept:=i64(0);for i in 0..r{keep[i]=true;for j in 0..r{if i==j{continue};mut ge:=true;mut gt:=false;for x in 0..c{l:=unsafe{a[2+j*c+x]};v:=unsafe{a[2+i*c+x]};if l<v{ge=false};if l>v{gt=true}};if ge&&(gt||j<i){keep[i]=false;break}};if keep[i]{kept++}};mut h:=feed(offset,kept);h=feed(h,c64);for i in 0..r{if keep[i]{for x in 0..c{h=feed(h,unsafe{a[2+i*c+x]})}}};return i64(h&u64(0x7fffffffffffffff))}
