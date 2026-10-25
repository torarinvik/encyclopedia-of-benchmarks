const N: usize=8; const Z:usize=64; const OUT:usize=36;
fn decode(v:i64)->f32{(v as f32)/1_000_000.0_f32}
fn put32(o:&mut [u8],p:usize,x:u32){o[p..p+4].copy_from_slice(&x.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn parboil_spmv_jds(input:*const i64,len:usize,output:*mut u8,cap:usize)->i64{
 if input.is_null()||len<3||len>164{return -1} let a=std::slice::from_raw_parts(input,len);
 if a[0]<1||a[0]>8||a[1]<1||a[1]>8||a[2]<1||a[2]>64{return -1}let n=a[0] as usize;let d=a[1] as usize;let z=a[2] as usize;
 if len!=4+3*n+d+2*z{return -1}let mut p=3;let mut row=[0i64;N];let mut perm=[0i64;N];let mut ptr=[0i64;N+1];let mut col=[0i64;Z];let mut dat=[0i64;Z];let mut vec=[0i64;N];
 for i in 0..n{if a[p]<0||a[p]>d as i64{return -1}row[i]=a[p];p+=1}if row[0]!=d as i64{return -1}for i in 1..n{if row[i]>row[i-1]{return -1}}
 for i in 0..n{perm[i]=a[p];p+=1}for i in 0..n{if perm[i]<0||perm[i]>=n as i64{return -1}for j in 0..i{if perm[j]==perm[i]{return -1}}}
 for k in 0..=d{ptr[k]=a[p];p+=1}for j in 0..z{col[j]=a[p];p+=1}for j in 0..z{dat[j]=a[p];p+=1}for i in 0..n{vec[i]=a[p];p+=1}
 let mut off=0usize;if ptr[0]!=0{return -1}for k in 0..d{let count=(0..n).filter(|&i|row[i]>k as i64).count();off+=count;if ptr[k+1]!=off as i64{return -1}}if off!=z{return -1}
 for j in 0..z{if col[j]<0||col[j]>=n as i64||dat[j]<-1_000_000||dat[j]>1_000_000{return -1}}for i in 0..n{if vec[i]<-1_000_000||vec[i]>1_000_000{return -1}}
 if output.is_null()||cap<4+4*n{return -2}let mut y=[0.0f32;N];let mut stage=[0u8;OUT];
 for i in 0..n{let mut acc=0.0f32;for k in 0..row[i] as usize{let j=ptr[k] as usize+i;let prod=decode(dat[j])*decode(vec[col[j] as usize]);acc=acc+prod}y[perm[i] as usize]=acc;}
 put32(&mut stage,0,n as u32);for i in 0..n{put32(&mut stage,4+4*i,y[i].to_bits())}std::ptr::copy_nonoverlapping(stage.as_ptr(),output,4+4*n);(4+4*n) as i64
}
