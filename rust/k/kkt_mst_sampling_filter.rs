const MAX_N: usize = 12;
const MAX_M: usize = 24;
const MAX_INPUT: usize = 98;

#[no_mangle]
pub unsafe extern "C" fn kkt_mst_sampling_filter(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<6 || length>MAX_INPUT { return -1; }
    let n64=*input; let m64=*input.add(1);
    if n64<2 || n64>MAX_N as i64 || m64<1 || m64>MAX_M as i64 || length!=2+4*m64 as usize { return -1; }
    let n=n64 as usize; let m=m64 as usize;
    let mut u=[0i64;MAX_M];let mut v=[0i64;MAX_M];let mut w=[0i64;MAX_M];let mut sample=[0i64;MAX_M];
    for i in 0..m { u[i]=*input.add(2+4*i);v[i]=*input.add(3+4*i);w[i]=*input.add(4+4*i);sample[i]=*input.add(5+4*i);
        if u[i]<0 || u[i]>=v[i] || v[i]>=n64 || w[i]<1 || w[i]>1024 || (sample[i]!=0&&sample[i]!=1){return -1;}
        for j in 0..i {if (u[i]==u[j]&&v[i]==v[j])||w[i]==w[j]{return -1;}}
    }
    if output.is_null()||capacity<m{return -2;}
    let mut order=[0usize;MAX_M];for i in 0..m{order[i]=i;}
    for i in 0..m{let mut best=i;for j in i+1..m{if w[order[j]]<w[order[best]]{best=j;}}order.swap(i,best);}
    let mut parent=[0usize;MAX_N];for i in 0..n{parent[i]=i;}
    let mut in_forest=[false;MAX_M];let mut staged=[0u8;MAX_M];
    for p in 0..m{let e=order[p];if sample[e]==0{continue;}let mut a=u[e] as usize;let mut b=v[e] as usize;while parent[a]!=a{a=parent[a];}while parent[b]!=b{b=parent[b];}if a!=b{parent[b]=a;in_forest[e]=true;}}
    for e in 0..m{
        if in_forest[e]{staged[e]=1;continue;}
        let mut path_max=[-1i64;MAX_N];let mut queue=[0usize;MAX_N];let mut seen=[false;MAX_N];let start=u[e] as usize;let target=v[e] as usize;let(mut head,mut tail)=(0usize,0usize);queue[tail]=start;tail+=1;seen[start]=true;path_max[start]=0;
        while head<tail&&!seen[target]{let cur=queue[head];head+=1;for k in 0..m{if !in_forest[k]{continue;}let next=if u[k] as usize==cur{Some(v[k] as usize)}else if v[k] as usize==cur{Some(u[k] as usize)}else{None};if let Some(q)=next{if !seen[q]{seen[q]=true;path_max[q]=path_max[cur].max(w[k]);queue[tail]=q;tail+=1;}}}}
        staged[e]=u8::from(!seen[target]||w[e]<path_max[target]);
    }
    for i in 0..m{*output.add(i)=staged[i];}m as i64
}
