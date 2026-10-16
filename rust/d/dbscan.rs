use std::slice;

#[no_mangle]
pub unsafe extern "C" fn dbscan(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 5 || length > 67 { return -1; }
    let v=slice::from_raw_parts(input,length);let n0=v[0];let eps=v[1];let minimum=v[2];
    if n0<1||n0>32||eps<1||eps>2_000_000||minimum<1||minimum>n0||length!=3+2*n0 as usize{return -1;}
    let n=n0 as usize;let mut x=[0i64;32];let mut y=[0i64;32];let mut labels=[-1i64;32];let mut expanded=[false;32];
    for i in 0..n{x[i]=v[3+2*i];y[i]=v[4+2*i];if !(-1_000_000..=1_000_000).contains(&x[i])||!(-1_000_000..=1_000_000).contains(&y[i]){return -1;}}
    if output.is_null()||capacity<n{return -2;}let e2=eps*eps;let mut next=0i64;
    for i in 0..n{if labels[i]>=0{continue;}let mut count=0;for j in 0..n{let dx=x[i]-x[j];let dy=y[i]-y[j];if dx*dx+dy*dy<=e2{count+=1;}}if count<minimum as usize{continue;}
      let cluster=next;next+=1;labels[i]=cluster;let mut queue=Vec::new();let mut queued=[false;32];for j in 0..n{let dx=x[i]-x[j];let dy=y[i]-y[j];if dx*dx+dy*dy<=e2{queue.push(j);queued[j]=true;}}
      let mut head=0;while head<queue.len(){let q=queue[head];head+=1;if labels[q]>=0&&labels[q]!=cluster{continue;}labels[q]=cluster;if expanded[q]{continue;}expanded[q]=true;let mut nc=0;for j in 0..n{let dx=x[q]-x[j];let dy=y[q]-y[j];if dx*dx+dy*dy<=e2{nc+=1;}}if nc>=minimum as usize{for j in 0..n{let dx=x[q]-x[j];let dy=y[q]-y[j];if dx*dx+dy*dy<=e2&&labels[j]<0&&!queued[j]{queue.push(j);queued[j]=true;}}}
      }
    }
    let out=slice::from_raw_parts_mut(output,n);for i in 0..n{out[i]=if labels[i]<0{0}else{(labels[i]+1)as u8};}n as i64
}
