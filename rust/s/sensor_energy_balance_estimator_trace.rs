const MAX_N: usize = 8;
const MAX_H: usize = 8;
const MAX_INPUT: usize = 82;
const INPUT_SCALE: i64 = 1_000_000;

unsafe fn put64(output:*mut u8,offset:usize,value:i64){let bits=value as u64;for b in 0..8{*output.add(offset+b)=(bits>>(8*b)) as u8;}}
fn gcd(mut a:i64,mut b:i64)->i64{while b!=0{let r=a%b;a=b;b=r;}a}

#[no_mangle]
pub unsafe extern "C" fn sensor_energy_balance_estimator_trace(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4||length>MAX_INPUT{return -1;}
    let n64=*input;let h64=*input.add(1);
    if n64<1||n64>8||h64<1||h64>8||length!=2+n64 as usize+h64 as usize+n64 as usize*h64 as usize{return -1;}
    let n=n64 as usize;let h=h64 as usize;let mut lambda=[0_i64;MAX_N];let mut sum=0_i64;
    for i in 0..n{lambda[i]=*input.add(2+i);if lambda[i]<0||lambda[i]>INPUT_SCALE{return -1;}sum+=lambda[i];}if sum!=INPUT_SCALE{return -1;}
    let full=(1_u64<<n)-1;let path_at=2+n;
    for t in 0..h{let mask=*input.add(path_at+t);if mask<=0||(mask as u64)&!full!=0{return -1;}}
    let mut lcm=1_i64;for t in 2..=h64{lcm=(lcm/gcd(lcm,t))*t;}let q=INPUT_SCALE*lcm;let draw_at=path_at+h;
    for i in 0..n*h{let draw=*input.add(draw_at+i);if draw<0||draw>=q{return -1;}}
    let mut state=[0_i64;MAX_N];for i in 0..n{state[i]=lambda[i]*lcm;}
    for t in 0..h{let divisor=t as i64+1;let delta=q/divisor;let path=*input.add(path_at+t) as u64;for i in 0..n{if state[i]<0||state[i]>q{return -1;}let draw=*input.add(draw_at+t*n+i);let r=if draw<state[i]{1_i64}else{0};let x=((path>>i)&1) as i64;let updated=state[i]+(x-r)*delta;if updated<0||updated>q{return -1;}state[i]=updated;}}
    let bytes=8*(1+n);if output.is_null()||capacity<bytes{return -2;}let mut staged=[0_u8;72];put64(staged.as_mut_ptr(),0,q);for i in 0..n{put64(staged.as_mut_ptr(),8*(i+1),state[i]);}for b in 0..bytes{*output.add(b)=staged[b];}bytes as i64
}
