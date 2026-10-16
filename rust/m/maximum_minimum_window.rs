fn store(value:i64,out:&mut [u8],pos:usize){out[pos..pos+8].copy_from_slice(&value.to_le_bytes());}
#[no_mangle]
pub unsafe extern "C" fn maximum_minimum_window(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2{return -2}let v=std::slice::from_raw_parts(input,length);let n0=v[0];if !(1..=256).contains(&n0)||length!=n0 as usize+1||v[1..].iter().any(|x|!(0..=1_000_000).contains(x)){return -2}let n=n0 as usize;if output.is_null()||capacity<n*8{return -3}
 let mut st:Vec<usize>=Vec::with_capacity(n);let mut left=vec![-1isize;n];let mut right=vec![n as isize;n];let mut ans=vec![0i64;n+1];
 for i in 0..n{while let Some(&j)=st.last(){if v[j+1]>=v[i+1]{st.pop();}else{break}}if let Some(&j)=st.last(){left[i]=j as isize}st.push(i);}
 st.clear();for ii in (0..n).rev(){while let Some(&j)=st.last(){if v[j+1]>=v[ii+1]{st.pop();}else{break}}if let Some(&j)=st.last(){right[ii]=j as isize}st.push(ii);}
 for i in 0..n{let len=(right[i]-left[i]-1) as usize;ans[len]=ans[len].max(v[i+1]);}for k in (1..n).rev(){ans[k]=ans[k].max(ans[k+1]);}
 let out=std::slice::from_raw_parts_mut(output,n*8);for i in 1..=n{store(ans[i],out,(i-1)*8)}n as i64
}
