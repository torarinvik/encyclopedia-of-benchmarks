const MAX_OPERATIONS: usize = 256;
const MAX_INPUT_LENGTH: usize = 514;
const MAX_LIVE_VALUES: usize = 64;
const NIL_SENTINEL: i64 = i64::MIN;

fn store_i64_le(output: *mut u8, offset: usize, value: i64) { let bits=value as u64;for byte in 0..8{unsafe{*output.add(offset+byte)=(bits>>(8*byte)) as u8;}} }
fn push_max(h:&mut [i32;MAX_LIVE_VALUES],n:&mut usize,x:i32){let mut p=*n;*n+=1;while p>0&&h[(p-1)/2]<x{let q=(p-1)/2;h[p]=h[q];p=q;}h[p]=x;}
fn pop_max(h:&mut [i32;MAX_LIVE_VALUES],n:&mut usize)->i32{let r=h[0];*n-=1;let x=h[*n];if *n==0{return r;}let mut p=0;while 2*p+1<*n{let mut c=2*p+1;if c+1<*n&&h[c+1]>h[c]{c+=1;}if h[c]<=x{break;}h[p]=h[c];p=c;}h[p]=x;r}
fn push_min(h:&mut [i32;MAX_LIVE_VALUES],n:&mut usize,x:i32){let mut p=*n;*n+=1;while p>0&&h[(p-1)/2]>x{let q=(p-1)/2;h[p]=h[q];p=q;}h[p]=x;}
fn pop_min(h:&mut [i32;MAX_LIVE_VALUES],n:&mut usize)->i32{let r=h[0];*n-=1;let x=h[*n];if *n==0{return r;}let mut p=0;while 2*p+1<*n{let mut c=2*p+1;if c+1<*n&&h[c+1]<h[c]{c+=1;}if h[c]>=x{break;}h[p]=h[c];p=c;}h[p]=x;r}

#[no_mangle]
pub unsafe extern "C" fn median_heap(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1||length>MAX_INPUT_LENGTH{return -1;}let values=std::slice::from_raw_parts(input,length);let op_value=values[0];
    if op_value<0||op_value>MAX_OPERATIONS as i64||length!=1+2*op_value as usize{return -1;}let count=op_value as usize;
    let mut lower=[0i32;MAX_LIVE_VALUES];let mut upper=[0i32;MAX_LIVE_VALUES];let mut lc=0usize;let mut uc=0usize;let mut results=[0i64;MAX_OPERATIONS];
    for i in 0..count{let op=values[1+2*i];let arg=values[2+2*i];if op==0{if arg<i32::MIN as i64||arg>i32::MAX as i64||lc+uc>=MAX_LIVE_VALUES{return -1;}let x=arg as i32;
        if lc==0{push_max(&mut lower,&mut lc,x);}else if x<lower[0]{push_max(&mut lower,&mut lc,x);if lc-uc>1{push_min(&mut upper,&mut uc,pop_max(&mut lower,&mut lc));}}else{push_min(&mut upper,&mut uc,x);if lc<uc{push_max(&mut lower,&mut lc,pop_min(&mut upper,&mut uc));}}results[i]=NIL_SENTINEL;
    }else if (1..=4).contains(&op){if arg!=0{return -1;}if op==1{results[i]=if lc>0{lower[0] as i64}else{NIL_SENTINEL};}else if op==2{if lc==0{results[i]=NIL_SENTINEL;}else{results[i]=pop_max(&mut lower,&mut lc) as i64;if lc<uc{push_max(&mut lower,&mut lc,pop_min(&mut upper,&mut uc));}}}else if op==3{results[i]=(lc+uc) as i64;}else{results[i]=if lc==0{1}else{0};}}
    else{return -1;}}
    let output_bytes=count*8;if output.is_null()||capacity<output_bytes{return -2;}for i in 0..count{store_i64_le(output,8*i,results[i]);}output_bytes as i64
}
