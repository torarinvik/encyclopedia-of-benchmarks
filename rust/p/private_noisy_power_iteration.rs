const S:i64=1_000_000;const MAX_N:usize=4;const MAX_L:usize=4;const MAX_INPUT:usize=39;

fn trunc_div(a:i64,b:i64)->i64{if a<0{-((-a)/b)}else{a/b}}
fn floor_sqrt(value:i64)->i64{let(mut low,mut high)=(0i64,13_000_001i64);while low+1<high{let middle=(low+high)/2;if middle<=value/middle{low=middle}else{high=middle}}low}
unsafe fn put64(out:*mut u8,pos:usize,value:i64){let bits=value as u64;for j in 0..8{*out.add(pos+j)=(bits>>(8*j))as u8;}}

#[no_mangle]
pub unsafe extern "C" fn private_noisy_power_iteration(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<11||length>MAX_INPUT{return -1;}
    let n64=*input;let l64=*input.add(1);let sigma=*input.add(2);
    if n64<2||n64>MAX_N as i64||l64<1||l64>MAX_L as i64||sigma<0||sigma>S||length!=3+n64 as usize*n64 as usize+n64 as usize+l64 as usize*n64 as usize{return -1;}
    let n=n64 as usize;let rounds=l64 as usize;let vstart=3+n*n;let nstart=vstart+n;
    let mut a=[0i64;MAX_N*MAX_N];let mut x=[0i64;MAX_N];let mut noise=[0i64;MAX_L*MAX_N];
    for i in 0..n*n{a[i]=*input.add(3+i);if a[i]<-S||a[i]>S{return -1;}}
    for i in 0..n{for j in 0..n{if a[i*n+j]!=a[j*n+i]{return -1;}}}
    let mut norm=0i64;for i in 0..n{x[i]=*input.add(vstart+i);if x[i]<-S||x[i]>S{return -1;}norm+=x[i]*x[i];}if norm!=S*S{return -1;}
    for i in 0..rounds*n{noise[i]=*input.add(nstart+i);if noise[i]<-2*S||noise[i]>2*S{return -1;}}
    let mut y=[0i64;MAX_N];
    for step in 0..rounds{let mut norm_sq=0i64;for i in 0..n{let mut sum=sigma*noise[step*n+i];for j in 0..n{sum+=a[i*n+j]*x[j];}y[i]=trunc_div(sum,S);norm_sq+=y[i]*y[i];}if norm_sq==0{return -1;}let radius=floor_sqrt(norm_sq);for i in 0..n{x[i]=trunc_div(y[i]*S,radius);}}
    let bytes=8*n;if output.is_null()||capacity<bytes{return -2;}let mut staged=[0u8;8*MAX_N];for i in 0..n{put64(staged.as_mut_ptr(),8*i,x[i]);}for i in 0..bytes{*output.add(i)=staged[i];}bytes as i64
}
