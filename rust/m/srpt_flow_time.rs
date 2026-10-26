const N:usize=12;const L:usize=26;
unsafe fn put64(o:*mut u8,p:usize,x:i64){let b=x as u64;for j in 0..8{*o.add(p+j)=(b>>(8*j)) as u8;}}
#[no_mangle]
pub unsafe extern "C" fn srpt_flow_time(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4||length>L{return -1;}let mr=*input;let nr=*input.add(1);
    if mr<1||mr>4||nr<1||nr>N as i64||length!=2+2*nr as usize{return -1;}
    let machines=mr as usize;let n=nr as usize;let mut release=[0i64;N];let mut rem=[0i64;N];let mut completion=[0i64;N];
    for i in 0..n{release[i]=*input.add(2+2*i);rem[i]=*input.add(3+2*i);if release[i]<0||release[i]>50||rem[i]<1||rem[i]>10{return -1;}}
    let bytes=8*(1+n);if output.is_null()||capacity<bytes{return -2;}
    let mut time=0i64;let mut done=0usize;
    while done<n{let mut chosen=[false;N];let mut selected=[0usize;N];let mut count=0usize;
        for _ in 0..machines{let mut best=n;for i in 0..n{if !chosen[i]&&rem[i]>0&&release[i]<=time&&(best==n||rem[i]<rem[best]||(rem[i]==rem[best]&&i<best)){best=i;}}if best==n{break;}chosen[best]=true;selected[count]=best;count+=1;}
        if count==0{let mut next=51i64;for i in 0..n{if rem[i]>0&&release[i]<next{next=release[i];}}time=next;}else{time+=1;for j in 0..count{let i=selected[j];rem[i]-=1;if rem[i]==0{completion[i]=time;done+=1;}}}
    }
    let mut total=0i64;for i in 0..n{total+=completion[i]-release[i];}put64(output,0,total);for i in 0..n{put64(output,8*(1+i),completion[i]);}bytes as i64
}
