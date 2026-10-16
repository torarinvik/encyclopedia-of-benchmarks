#[no_mangle]
pub unsafe extern "C" fn palindromic_partitioning(v:*const i64,n:usize)->i64{
 if v.is_null()||n<2||n>65{return -1}let a=std::slice::from_raw_parts(v,n);
 if !(1..=64).contains(&a[0])||n!=a[0] as usize+1{return -1}let m=a[0] as usize;
 let mut p=[[false;64];64];let mut cuts=[0i64;64];
 for end in 0..m{let x=a[end+1];if !(0..=127).contains(&x){return -1}for start in 0..=end{p[start][end]=a[start+1]==x&&(end-start<2||p[start+1][end-1]);}}
 for end in 0..m{if p[0][end]{cuts[end]=0}else{cuts[end]=64;for start in 1..=end{if p[start][end]&&cuts[start-1]+1<cuts[end]{cuts[end]=cuts[start-1]+1}}}}
 cuts[m-1]
}
