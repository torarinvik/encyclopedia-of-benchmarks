/// Static range minimum queries using a sparse table.
const N:usize=64; const Q:usize=64; const BAD:i64=i64::MIN;
fn put(out:&mut [u8],at:usize,value:i64){out[at..at+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn range_minimum_query(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<4{return -1}let x=std::slice::from_raw_parts(input,length);if !(1..=N as i64).contains(&x[0]){return -1}let n=x[0] as usize;let qp=1+n;if length<=qp{return -1}if !(1..=Q as i64).contains(&x[qp]){return -1}let q=x[qp] as usize;if length!=qp+1+2*q{return -1}
 let values=&x[1..1+n];if values.iter().any(|v|!(-1000..=1000).contains(v)){return -1}if capacity<q*8||output.is_null(){return -2}
 let mut table=[[0usize;N];7];for i in 0..n{table[0][i]=i}let mut k=1;while (1usize<<k)<=n{let width=1usize<<k;let half=width>>1;for i in 0..=n-width{let a=table[k-1][i];let b=table[k-1][i+half];table[k][i]=if values[a]<values[b]{a}else{b}}k+=1}
 let out=std::slice::from_raw_parts_mut(output,q*8);for j in 0..q{let l=x[qp+1+2*j];let r=x[qp+2+2*j];let ans=if l>=0&&r>l&&r<=n as i64{let l=l as usize;let r=r as usize;let len=r-l;let k=(usize::BITS-1-len.leading_zeros()) as usize;let width=1usize<<k;let a=table[k][l];let b=table[k][r-width];if values[a]<values[b]{values[a]}else{values[b]}}else{BAD};put(out,j*8,ans)}q as i64*8
}
