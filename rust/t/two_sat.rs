const MAX_VARIABLES: usize = 40;
const MAX_CLAUSES: usize = 2047;
const MAX_LITERALS: usize = 2 * MAX_VARIABLES;
fn fill(graph: &[[bool; MAX_LITERALS]; MAX_LITERALS], n: usize, v: usize,
        seen: &mut [bool; MAX_LITERALS], order: &mut [usize; MAX_LITERALS], len: &mut usize) {
    seen[v] = true;
    for w in 0..n { if graph[v][w] && !seen[w] { fill(graph,n,w,seen,order,len); } }
    order[*len] = v; *len += 1;
}
fn collect(graph: &[[bool; MAX_LITERALS]; MAX_LITERALS], n: usize, v: usize,
           component: &mut [i32; MAX_LITERALS], id: i32) {
    component[v]=id;
    for w in 0..n { if graph[v][w] && component[w]<0 { collect(graph,n,w,component,id); } }
}
#[no_mangle]
pub unsafe extern "C" fn two_sat(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length<2 || length>2+2*MAX_CLAUSES { return -1; }
    let nv=*input; let mc=*input.add(1);
    if nv<0 || nv>MAX_VARIABLES as i64 || mc<0 || mc>MAX_CLAUSES as i64 { return -1; }
    let variables=nv as usize; let clauses=mc as usize; let n=2*variables;
    if length!=2+2*clauses { return -1; }
    let mut graph=[[false;MAX_LITERALS];MAX_LITERALS]; let mut transpose=[[false;MAX_LITERALS];MAX_LITERALS];
    for i in 0..clauses {
        let a=*input.add(2+2*i); let b=*input.add(3+2*i);
        if a==0 || b==0 || a.abs()>nv || b.abs()>nv { return -1; }
        let lit=|x:i64| -> usize { 2*(x.abs() as usize-1)+usize::from(x<0) };
        let x=lit(a); let y=lit(b);
        for (u,v) in [(x^1,y),(y^1,x)] { graph[u][v]=true; transpose[v][u]=true; }
    }
    let mut seen=[false;MAX_LITERALS]; let mut order=[0usize;MAX_LITERALS]; let mut len=0;
    for v in 0..n { if !seen[v] { fill(&graph,n,v,&mut seen,&mut order,&mut len); } }
    let mut component=[-1i32;MAX_LITERALS]; let mut id=0;
    while len>0 { len-=1; let v=order[len]; if component[v]<0 { collect(&transpose,n,v,&mut component,id); id+=1; } }
    let satisfiable=(0..variables).all(|i|component[2*i]!=component[2*i+1]);
    let outlen=if satisfiable { variables+1 } else { 1 };
    if output.is_null() || capacity<outlen { return -2; }
    *output=u8::from(satisfiable);
    if satisfiable { for i in 0..variables { *output.add(i+1)=u8::from(component[2*i]>component[2*i+1]); } }
    outlen as i64
}
