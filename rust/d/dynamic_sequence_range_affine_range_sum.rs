const MOD: i64 = 998_244_353;
const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_NODES: usize = 64;
const MAX_INPUT: usize = 195;

#[derive(Clone, Copy, Default)]
struct Node { left: i32, right: i32, size: usize, value: i64, sum: i64, mul: i64, add: i64, priority: u64, reversed: bool }
#[derive(Clone, Copy, Default)]
struct Operation { kind: i32, left: usize, right: usize, node: i32, mul: i64, add: i64 }

fn priority_for(id: usize) -> u64 { let mut state=1i64; for _ in 0..=id { state=(state*48271)%2_147_483_647; } state as u64 }
fn node_size(t: &[Node; MAX_NODES], x: i32) -> usize { if x < 0 { 0 } else { t[x as usize].size } }
fn node_sum(t: &[Node; MAX_NODES], x: i32) -> i64 { if x < 0 { 0 } else { t[x as usize].sum } }
fn higher(t: &[Node; MAX_NODES], a: i32, b: i32) -> bool { let x=t[a as usize]; let y=t[b as usize]; if x.priority!=y.priority { x.priority>y.priority } else { a>b } }
fn pull(t: &mut [Node; MAX_NODES], x: i32) { let i=x as usize; t[i].size=1+node_size(t,t[i].left)+node_size(t,t[i].right); t[i].sum=(t[i].value+node_sum(t,t[i].left)+node_sum(t,t[i].right))%MOD; }
fn affine(t: &mut [Node; MAX_NODES], x: i32, m: i64, a: i64) { if x<0{return;} let i=x as usize; t[i].value=(m*t[i].value+a)%MOD; t[i].sum=(m*t[i].sum+a*t[i].size as i64)%MOD; t[i].mul=(m*t[i].mul)%MOD; t[i].add=(m*t[i].add+a)%MOD; }
fn reverse_node(t: &mut [Node; MAX_NODES], x: i32) { if x<0{return;} let i=x as usize; let left=t[i].left; t[i].left=t[i].right; t[i].right=left; t[i].reversed=!t[i].reversed; }
fn push(t: &mut [Node; MAX_NODES], x: i32) { let i=x as usize; let n=t[i]; if n.mul!=1||n.add!=0 { affine(t,n.left,n.mul,n.add); affine(t,n.right,n.mul,n.add); t[i].mul=1; t[i].add=0; } if n.reversed { reverse_node(t,n.left); reverse_node(t,n.right); t[i].reversed=false; } }
fn split(t: &mut [Node; MAX_NODES], root: i32, count: usize) -> (i32,i32) { if root<0{return(-1,-1);} push(t,root); let i=root as usize; if node_size(t,t[i].left)>=count { let (a,b)=split(t,t[i].left,count); t[i].left=b; pull(t,root); (a,root) } else { let left_size=node_size(t,t[i].left); let (a,b)=split(t,t[i].right,count-left_size-1); t[i].right=a; pull(t,root); (root,b) } }
fn merge(t: &mut [Node; MAX_NODES], a: i32, b: i32) -> i32 { if a<0{return b;} if b<0{return a;} if higher(t,a,b) { push(t,a); let i=a as usize; let child=t[i].right; t[i].right=merge(t,child,b); pull(t,a); a } else { push(t,b); let i=b as usize; let child=t[i].left; t[i].left=merge(t,a,child); pull(t,b); b } }
unsafe fn put64(out: *mut u8, at: usize, value: i64) { let bits=value as u64; for j in 0..8 { *out.add(at+j)=(bits>>(8*j)) as u8; } }

#[no_mangle]
pub unsafe extern "C" fn dynamic_sequence_range_affine_range_sum(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null()||length<2||length>MAX_INPUT{return -1;} let n64=*input; let q64=*input.add(1);
    if n64<0||n64>MAX_N as i64||q64<0||q64>MAX_Q as i64{return -1;} let n=n64 as usize; let q=q64 as usize; let mut offset=2usize;
    if length<2+n{return -1;} let mut nodes=[Node::default();MAX_NODES];
    for i in 0..n { let v=*input.add(offset); offset+=1; if v<0||v>=MOD{return -1;} nodes[i]=Node{left:-1,right:-1,size:1,value:v,sum:v,mul:1,add:0,priority:priority_for(i),reversed:false}; }
    let mut ops=[Operation::default();MAX_Q]; let mut current=n; let mut node_count=n; let mut queries=0usize;
    for i in 0..q { if offset>=length{return -1;} let tag=*input.add(offset); offset+=1; if !(0..=4).contains(&tag){return -1;} let mut op=Operation{kind:tag as i32,left:0,right:0,node:-1,mul:0,add:0};
        if tag==0 { if offset+2>length{return -1;} let at=*input.add(offset); let v=*input.add(offset+1); offset+=2; if at<0||at as usize>current||current>=MAX_NODES||v<0||v>=MOD{return -1;} op.left=at as usize; op.node=node_count as i32; nodes[node_count]=Node{left:-1,right:-1,size:1,value:v,sum:v,mul:1,add:0,priority:priority_for(node_count),reversed:false}; node_count+=1; current+=1; }
        else if tag==1 { if offset>=length{return -1;} let at=*input.add(offset); offset+=1; if at<0||at as usize>=current{return -1;} op.left=at as usize; current-=1; }
        else if tag==2||tag==4 { if offset+2>length{return -1;} let l=*input.add(offset); let r=*input.add(offset+1); offset+=2; if l<0||l>r||r as usize>current{return -1;} op.left=l as usize; op.right=r as usize; if tag==4{queries+=1;} }
        else { if offset+4>length{return -1;} let l=*input.add(offset);let r=*input.add(offset+1);let m=*input.add(offset+2);let a=*input.add(offset+3);offset+=4;if l<0||l>r||r as usize>current||m<0||m>=MOD||a<0||a>=MOD{return -1;}op.left=l as usize;op.right=r as usize;op.mul=m;op.add=a; }
        ops[i]=op;
    }
    if offset!=length{return -1;} let mut root=-1; for i in 0..n{root=merge(&mut nodes,root,i as i32);} let mut answers=[0i64;MAX_Q];let mut answer_count=0usize;
    for op in ops.iter().take(q) { let (prefix,suffix)=split(&mut nodes,root,op.left); if op.kind==0 {root=merge(&mut nodes,merge(&mut nodes,prefix,op.node),suffix);continue;} if op.kind==1 {let (removed,tail)=split(&mut nodes,suffix,1);let _=removed;root=merge(&mut nodes,prefix,tail);continue;} let (middle,tail)=split(&mut nodes,suffix,op.right-op.left); if op.kind==2{reverse_node(&mut nodes,middle);}else if op.kind==3{affine(&mut nodes,middle,op.mul,op.add);}else{answers[answer_count]=node_sum(&nodes,middle);answer_count+=1;} root=merge(&mut nodes,merge(&mut nodes,prefix,middle),tail); }
    let bytes=8*queries;if output.is_null()||capacity<bytes{return -2;}for i in 0..queries{put64(output,8*i,answers[i]);}bytes as i64
}
