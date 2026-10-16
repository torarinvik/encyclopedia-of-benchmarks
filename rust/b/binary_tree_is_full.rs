const MAX_N:i64=1024;
#[no_mangle]
pub unsafe extern "C" fn binary_tree_is_full(input:*const i64,length:usize)->i64{
    if input.is_null()||length<2{return -1;}let a=std::slice::from_raw_parts(input,length);
    if a[0]<1||a[0]>MAX_N{return -1;}let n=a[0]as usize;let root=a[1];if root<0||root>=n as i64||length!=2+2*n{return -1;}
    let(mut left,mut right,mut parents)=(vec![-1isize;n],vec![-1isize;n],vec![0usize;n]);let mut full=true;
    for i in 0..n{let l=a[2+2*i];let r=a[3+2*i];if l< -1||l>=n as i64||r< -1||r>=n as i64||l==i as i64||r==i as i64{return -1;}left[i]=l as isize;right[i]=r as isize;if l>=0{parents[l as usize]+=1;}if r>=0{parents[r as usize]+=1;}if (l<0)!=(r<0){full=false;}}
    let root=root as usize;if parents[root]!=0{return -1;}for i in 0..n{if i!=root&&parents[i]!=1{return -1;}}
    let(mut stack,mut seen,mut visited)=(vec![root],vec![false;n],0usize);while let Some(node)=stack.pop(){if seen[node]{return -1;}seen[node]=true;visited+=1;if left[node]>=0{stack.push(left[node] as usize);}if right[node]>=0{stack.push(right[node] as usize);}}
    if visited!=n{return -1;}if full{1}else{0}
}
