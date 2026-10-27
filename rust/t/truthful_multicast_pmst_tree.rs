const MAX_N: usize = 8;
const MAX_M: usize = 28;
const MAX_INPUT: usize = 95;
const MAX_OUTPUT: usize = 176;

fn find_root(parent: &mut [usize; MAX_N], mut x: usize) -> usize {
    while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; }
    x
}

#[no_mangle]
pub unsafe extern "C" fn truthful_multicast_pmst_tree(values: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let a = std::slice::from_raw_parts(values, length);
    if a[0] < 2 || a[0] > MAX_N as i64 || a[1] < a[0]-1 || a[1] > MAX_M as i64 ||
       a[2] < 0 || a[2] >= a[0] || a[3] < 1 || a[3] >= a[0] { return -1; }
    let (n,m,source,r) = (a[0] as usize,a[1] as usize,a[2] as usize,a[3] as usize);
    if length != 4+3*m+r { return -1; }
    let mut eu=[0usize;MAX_M]; let mut ev=[0usize;MAX_M]; let mut ew=[0i64;MAX_M]; let mut order=[0usize;MAX_M];
    let (mut pu,mut pv)=(-1i64,-1i64);
    for i in 0..m {
        let (u,v,w)=(a[4+3*i],a[5+3*i],a[6+3*i]);
        if u<0||v<=u||v>=n as i64||w<1||w>100||(i>0&&(u<pu||(u==pu&&v<=pv))){return -1;}
        eu[i]=u as usize;ev[i]=v as usize;ew[i]=w;order[i]=i;pu=u;pv=v;
    }
    let mut receivers=[0usize;MAX_N];let mut last=-1i64;
    for i in 0..r {let x=a[4+3*m+i];if x<0||x>=n as i64||x==source as i64||(i>0&&x<=last){return -1;}receivers[i]=x as usize;last=x;}
    for i in 1..m {let key=order[i];let mut j=i;while j>0 {let q=order[j-1];if ew[q]<ew[key]||(ew[q]==ew[key]&&(eu[q]<eu[key]||(eu[q]==eu[key]&&ev[q]<ev[key]))){break;}order[j]=q;j-=1;}order[j]=key;}
    let mut dsu=[0usize;MAX_N];for i in 0..n{dsu[i]=i;}
    let mut tu=[0usize;MAX_N];let mut tv=[0usize;MAX_N];let mut tw=[0i64;MAX_N];let mut te=0;
    for z in 0..m {if te>=n-1{break;}let e=order[z];let x=find_root(&mut dsu,eu[e]);let y=find_root(&mut dsu,ev[e]);if x!=y{dsu[x]=y;tu[te]=eu[e];tv[te]=ev[e];tw[te]=ew[e];te+=1;}}
    if te!=n-1{return -1;}
    let mut edge_at=[[None;MAX_N];MAX_N];for e in 0..te{edge_at[tu[e]][tv[e]]=Some(e);edge_at[tv[e]][tu[e]]=Some(e);}
    let mut parent=[usize::MAX;MAX_N];let mut parent_edge=[usize::MAX;MAX_N];parent[source]=source;let mut stack=[0usize;MAX_N];let mut top=1;stack[0]=source;
    while top>0{top-=1;let u=stack[top];for v in 0..n{if let Some(e)=edge_at[u][v]{if parent[v]==usize::MAX{parent[v]=u;parent_edge[v]=e;stack[top]=v;top+=1;}}}}
    let mut keep=[false;MAX_N];for &receiver in &receivers[..r]{let mut v=receiver;while v!=source{if parent[v]==usize::MAX{return -1;}keep[parent_edge[v]]=true;v=parent[v];}}
    let mut selected=[0usize;MAX_N];let mut count=0;for e in 0..te{if keep[e]{selected[count]=e;count+=1;}}
    for i in 1..count{let key=selected[i];let mut j=i;while j>0&&(tu[selected[j-1]]>tu[key]||(tu[selected[j-1]]==tu[key]&&tv[selected[j-1]]>tv[key])){selected[j]=selected[j-1];j-=1;}selected[j]=key;}
    let bytes=8*(1+3*count);if output.is_null()||capacity<bytes{return -2;}
    let mut staged=[0u8;MAX_OUTPUT];staged[..8].copy_from_slice(&(count as i64).to_le_bytes());
    for i in 0..count{let e=selected[i];for (j,x) in [tu[e] as i64,tv[e] as i64,tw[e]].iter().enumerate(){staged[8*(1+3*i+j)..8*(2+3*i+j)].copy_from_slice(&x.to_le_bytes());}}
    std::ptr::copy_nonoverlapping(staged.as_ptr(),output,bytes);bytes as i64
}
