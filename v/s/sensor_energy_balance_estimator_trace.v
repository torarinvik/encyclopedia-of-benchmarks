@[export: 'sensor_energy_balance_estimator_trace']
pub fn sensor_energy_balance_estimator_trace(input &i64,length usize,output &u8,capacity usize)i64{
	unsafe{
		if input==nil||length<4||length>82{return -1}
		n64:=input[0];h64:=input[1]
		if n64<1||n64>8||h64<1||h64>8||length!=usize(2+n64+h64+n64*h64){return -1}
		n:=int(n64);h:=int(h64);mut lambda:=[8]i64{};mut sum:=i64(0)
		for i in 0..n{lambda[i]=input[2+i];if lambda[i]<0||lambda[i]>1000000{return -1};sum+=lambda[i]};if sum!=1000000{return -1}
		full:=(u64(1)<<n)-1;path_at:=2+n
		for t in 0..h{mask:=input[path_at+t];if mask<=0||(u64(mask)&~full)!=0{return -1}}
		mut lcm:=i64(1);for t in 2..h+1{lcm=(lcm/gcd_i64(lcm,i64(t)))*i64(t)};q:=i64(1000000)*lcm;draw_at:=path_at+h
		for i in 0..n*h{if input[draw_at+i]<0||input[draw_at+i]>=q{return -1}}
		mut state:=[8]i64{};for i in 0..n{state[i]=lambda[i]*lcm}
		for t in 0..h{divisor:=i64(t+1);delta:=q/divisor;path:=u64(input[path_at+t]);for i in 0..n{if state[i]<0||state[i]>q{return -1};r:=i64(0);if input[draw_at+t*n+i]<state[i]{r=1};x:=i64((path>>i)&1);updated:=state[i]+(x-r)*delta;if updated<0||updated>q{return -1};state[i]=updated}}
		bytes:=8*(1+n);if output==nil||capacity<usize(bytes){return -2};mut staged:=[72]u8{};put(mut &staged[0],0,q);for i in 0..n{put(mut &staged[0],8*(i+1),state[i])};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
	}
}

fn gcd_i64(a0 i64,b0 i64)i64{mut a:=a0;mut b:=b0;for b!=0{r:=a%b;a=b;b=r};return a}
