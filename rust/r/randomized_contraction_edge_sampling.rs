const MAX_N: usize=16;const MAX_M:usize=24;const MAX_INPUT:usize=74;

unsafe fn put32(out:*mut u8,pos:usize,value:i32){let bits=value as u32;for j in 0..4{*out.add(pos+j)=(bits>>(8*j)) as u8;}}

#[no_mangle]
pub unsafe extern "C" fn randomized_contraction_edge_sampling(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<5||length>MAX_INPUT{return -1;}
    let n64=*input;let m64=*input.add(1);
    if n64<2||n64>MAX_N as i64||m64<n64-1||m64>MAX_M as i64||length!=2+3*m64 as usize{return -1;}
    let n=n64 as usize;let m=m64 as usize;let mut u=[0i64;MAX_M];let mut v=[0i64;MAX_M];let mut bit=[0i64;MAX_M];
    for i in 0..m{u[i]=*input.add(2+3*i);v[i]=*input.add(3+3*i);bit[i]=*input.add(4+3*i);if u[i]<0||u[i]>=v[i]||v[i]>=n64||(bit[i]!=0&&bit[i]!=1){return -1;}for j in 0..i{if u[i]==u[j]&&v[i]==v[j]{return -1;}}}
    let mut seen=[false;MAX_N];let mut queue=[0usize;MAX_N];let(mut head,mut tail)=(0usize,1usize);queue[0]=0;seen[0]=true;
    while head<tail{let current=queue[head];head+=1;for e in 0..m{let next=if u[e] as usize==current{Some(v[e] as usize)}else if v[e] as usize==current{Some(u[e] as usize)}else{None};if let Some(node)=next{if !seen[node]{seen[node]=true;queue[tail]=node;tail+=1;}}}}
    if tail!=n{return -1;}
    let mut parent=[0usize;MAX_N];for i in 0..n{parent[i]=i;}
    for e in 0..m{if bit[e]!=0{let mut a=u[e] as usize;let mut b=v[e] as usize;while parent[a]!=a{a=parent[a];}while parent[b]!=b{b=parent[b];}if a!=b{parent[b]=a;}}}
    let mut minimum=[n;MAX_N];for vertex in 0..n{let mut root=vertex;while parent[root]!=root{root=parent[root];}minimum[root]=minimum[root].min(vertex);}
    let bytes=4*n;if output.is_null()||capacity<bytes{return -2;}
    let mut staged=[0u8;4*MAX_N];for vertex in 0..n{let mut root=vertex;while parent[root]!=root{root=parent[root];}put32(staged.as_mut_ptr(),4*vertex,minimum[root] as i32);}
    for i in 0..bytes{*output.add(i)=staged[i];}bytes as i64
}
