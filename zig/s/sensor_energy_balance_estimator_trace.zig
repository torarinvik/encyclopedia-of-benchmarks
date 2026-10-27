const max_n:usize=8;const max_input:usize=82;const input_scale:i64=1_000_000;
fn gcd(a0:i64,b0:i64)i64{var a=a0;var b=b0;while(b!=0){const r=@rem(a,b);a=b;b=r;}return a;}
fn put64(output:[*]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|output[offset+b]=@truncate(bits>>@intCast(8*b));}

export fn sensor_energy_balance_estimator_trace(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    if(input_opt==null or length<4 or length>max_input)return -1;
    const input=input_opt.?;const n64=input[0];const h64=input[1];
    if(n64<1 or n64>8 or h64<1 or h64>8 or length!=2+@as(usize,@intCast(n64))+@as(usize,@intCast(h64))+@as(usize,@intCast(n64*h64)))return -1;
    const n:usize=@intCast(n64);const h:usize=@intCast(h64);var lambda:[max_n]i64=@splat(0);var sum:i64=0;
    for(0..n)|i|{lambda[i]=input[2+i];if(lambda[i]<0 or lambda[i]>input_scale)return -1;sum+=lambda[i];}if(sum!=input_scale)return -1;
    const full=(@as(u64,1)<<@intCast(n))-1;const path_at=2+n;
    for(0..h)|t|{const mask=input[path_at+t];if(mask<=0 or (@as(u64,@intCast(mask))&~full)!=0)return -1;}
    var lcm:i64=1;for(2..h64+1)|t|{lcm=(lcm/gcd(lcm,@intCast(t)))*@intCast(t);}const q=input_scale*lcm;const draw_at=path_at+h;
    for(0..n*h)|i|{if(input[draw_at+i]<0 or input[draw_at+i]>=q)return -1;}
    var state:[max_n]i64=@splat(0);for(0..n)|i|state[i]=lambda[i]*lcm;
    for(0..h)|t|{const divisor:i64=@intCast(t+1);const delta=q/divisor;const path:@TypeOf(full)=@intCast(input[path_at+t]);for(0..n)|i|{if(state[i]<0 or state[i]>q)return -1;const r:i64=if(input[draw_at+t*n+i]<state[i]) 1 else 0;const x:i64=@intCast((path>>@intCast(i))&1);const updated=state[i]+(x-r)*delta;if(updated<0 or updated>q)return -1;state[i]=updated;}}
    const bytes=8*(1+n);if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;var staged:[72]u8=@splat(0);put64(&staged,0,q);for(0..n)|i|put64(&staged,8*(i+1),state[i]);for(0..bytes)|i|output[i]=staged[i];return @intCast(bytes);
}
