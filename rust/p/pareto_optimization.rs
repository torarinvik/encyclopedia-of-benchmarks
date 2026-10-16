const OFFSET:u64=14695981039346656037;const PRIME:u64=1099511628211;
fn feed(mut h:u64,v:i64)->u64{for b in v.to_le_bytes(){h=(h^u64::from(b)).wrapping_mul(PRIME);}h}
#[no_mangle]
pub extern "C" fn pareto_optimization(input:*const i64,len:usize)->i64{
 if input.is_null()||len<2||len>514{return -1;}let a=unsafe{std::slice::from_raw_parts(input,len)};let(r64,c64)=(a[0],a[1]);
 if r64<1||r64>64||c64<1||c64>8||len!=2+(r64*c64)as usize{return -1;}let(r,c)=(r64 as usize,c64 as usize);
 if a[2..].iter().any(|&v|v < -1000||v>1000){return -1;}let mut keep=[false;64];let mut kept=0i64;
 for i in 0..r{keep[i]=true;for j in 0..r{if i==j{continue;}let(mut ge,mut gt)=(true,false);for x in 0..c{let(l,v)=(a[2+j*c+x],a[2+i*c+x]);if l<v{ge=false;}if l>v{gt=true;}}if ge&&(gt||j<i){keep[i]=false;break;}}if keep[i]{kept+=1;}}
 let mut h=feed(OFFSET,kept);h=feed(h,c64);for i in 0..r{if keep[i]{for x in 0..c{h=feed(h,a[2+i*c+x]);}}}(h&0x7fff_ffff_ffff_ffff)as i64
}
