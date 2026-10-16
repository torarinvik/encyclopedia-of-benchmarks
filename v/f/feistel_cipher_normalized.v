module feistel_cipher_normalized
fn rk(k u32, r u32) u32 { mut p:=u32(1);for _ in 0..(r+2){p*=k};return p^k }
fn f(initial u32,k u32) u32 { mut x:=initial;for _ in 0..32{x=((x^u32(0x55555555))*x)%k;x^=k};return x }
@[export: 'feistel_cipher_normalized']
pub fn feistel_cipher_normalized(a &i64,length usize) i64 { if unsafe{a==nil}||length!=3{return -1};if unsafe{a[0]<0||a[0]>1||a[1]<1||u64(a[1])>0xffffffff}{return -1};key:=u32(unsafe{a[1]});for i in 0..32{if rk(key,u32(i))==0{return -1}};b:=u64(unsafe{a[2]});mut l:=u32(b>>32);mut r:=u32(b);if unsafe{a[0]}==0{for i in 0..32{t:=r^f(l,rk(key,u32(i)));r=l;l=t}}else{for i in 0..32{j:=31-i;t:=l^f(r,rk(key,u32(j)));l=r;r=t}};return i64((u64(l)<<32)|u64(r))}
