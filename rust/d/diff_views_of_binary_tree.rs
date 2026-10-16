use std::slice;
#[no_mangle]
pub unsafe extern "C" fn diff_views_of_binary_tree(a:*const i64,n:usize,root:i64,view:i64,out:*mut i64,cap:usize)->i64 {
 if n>1023||!(0..=3).contains(&view){return -1} if n==0{return if root == -1 {0}else{-1}}
 if a.is_null()||root<0||root as usize>=n{return -1} if out.is_null()||cap<n{return -2}
 let a=slice::from_raw_parts(a,3*n); let mut parents=vec![0usize;n];
 for i in 0..n {let v=a[3*i];let l=a[3*i+1];let r=a[3*i+2];if v<i32::MIN as i64||v>i32::MAX as i64||l < -1||r < -1||l>=n as i64||r>=n as i64{return -1}for c in [l,r]{if c>=0{parents[c as usize]+=1;if parents[c as usize]>1{return -1}}}}
 if parents[root as usize]!=0||(0..n).any(|i|i!=root as usize&&parents[i]!=1){return -1}
 let mut q=vec![root as usize];let mut dep=vec![0usize;n];let mut col=vec![0i32;n];let mut seen=vec![false;n];seen[root as usize]=true;let mut fd=vec![None;n];let mut ld=vec![None;n];let mut fc=vec![None;2*n+1];let mut lc=vec![None;2*n+1];let(mut head,mut maxd,mut minc,mut maxc)=(0usize,0usize,0i32,0i32);
 while head<q.len(){let u=q[head];head+=1;let d=dep[u];let c=col[u];let v=a[3*u];maxd=maxd.max(d);minc=minc.min(c);maxc=maxc.max(c);if fd[d].is_none(){fd[d]=Some(v)}ld[d]=Some(v);let s=(c+n as i32) as usize;if fc[s].is_none(){fc[s]=Some(v)}lc[s]=Some(v);for (k,ch) in [a[3*u+1],a[3*u+2]].iter().enumerate(){if *ch>=0{let x=*ch as usize;if seen[x]{return -1}seen[x]=true;dep[x]=d+1;col[x]=c+if k==0{-1}else{1};q.push(x)}}}
 if q.len()!=n{return -1}let mut res=Vec::new();if view<2{for d in 0..=maxd{let x=if view==0{ld[d]}else{fd[d]};if let Some(v)=x{res.push(v)}}}else{for c in minc..=maxc{let s=(c+n as i32)as usize;let x=if view==2{fc[s]}else{lc[s]};if let Some(v)=x{res.push(v)}}}for(i,v)in res.iter().enumerate(){*out.add(i)=*v}res.len() as i64
}
