const MAX_TEXT: usize=512;const ALPHABET:usize=128;const INVALID:i64=-1;
fn round_even(v:f64)->i32{let lo=v.floor();let f=v-lo;if f<0.5{lo as i32}else if f>0.5{(lo+1.0) as i32}else{let i=lo as i32;if i%2==0{i}else{i+1}}}
fn emit_line(out:&mut[u8],mut pos:usize,value:i32)->usize{let mut v=value;if v<0{out[pos]=b'-';pos+=1;v=-v;}if v>=10{out[pos]=b'0'+(v/10) as u8;pos+=1;}out[pos]=b'0'+(v%10) as u8;pos+=1;out[pos]=b'.';out[pos+1]=b'0';out[pos+2]=b'\n';pos+3}
/// Emit the source's rounded single-character entropy, bigram entropy, and difference.
#[no_mangle]
pub extern "C" fn entropy(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>MAX_TEXT+1{return INVALID;}let v=unsafe{std::slice::from_raw_parts(input,length)};let n=v[0];if n<1||n>MAX_TEXT as i64||length!=n as usize+1{return INVALID;}
 let mut singles=[0u32;ALPHABET];let mut pairs=[0u32;ALPHABET*ALPHABET];for i in 0..n as usize{let c=v[i+1];if !(0..128).contains(&c){return INVALID;}singles[c as usize]+=1;}pairs[32*ALPHABET+v[1] as usize]+=1;for i in 0..(n as usize-1){pairs[(v[i+1] as usize)*ALPHABET+v[i+2] as usize]+=1;}
 let mut alpha=[0usize;27];alpha[0]=32;for i in 1..27{alpha[i]=96+i;}let mut s1=0.0;let mut s2=0.0;for &a in &alpha{let c=singles[a];if c>0{let p=c as f64/n as f64;s1+=p*p.log2();}}for &a in &alpha{for &b in &alpha{let c=pairs[a*ALPHABET+b];if c>0{let p=c as f64/n as f64;s2+=p*p.log2();}}}
 let mut temp=[0u8;32];let mut pos=0;pos=emit_line(&mut temp,pos,round_even(-s1));pos=emit_line(&mut temp,pos,round_even(-s2));pos=emit_line(&mut temp,pos,round_even((-s2)-(-s1)));if output.is_null()||capacity<pos{return -2;}let out=unsafe{std::slice::from_raw_parts_mut(output,capacity)};out[..pos].copy_from_slice(&temp[..pos]);pos as i64
}
