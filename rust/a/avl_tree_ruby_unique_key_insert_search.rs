const MAX_NODES: usize = 64;
const MAX_OPS: usize = 128;
#[derive(Clone, Copy)]
struct Node { key:i64, left:i32, right:i32, height:i32 }
fn h(nodes:&[Node;MAX_NODES],i:i32)->i32{if i<0{0}else{nodes[i as usize].height}}
fn update(nodes:&mut [Node;MAX_NODES],i:usize){let a=h(nodes,nodes[i].left);let b=h(nodes,nodes[i].right);nodes[i].height=1+a.max(b);}
fn rotate_right(nodes:&mut [Node;MAX_NODES],root:usize)->usize{let pivot=nodes[root].left as usize;let middle=nodes[pivot].right;nodes[pivot].right=root as i32;nodes[root].left=middle;update(nodes,root);update(nodes,pivot);pivot}
fn rotate_left(nodes:&mut [Node;MAX_NODES],root:usize)->usize{let pivot=nodes[root].right as usize;let middle=nodes[pivot].left;nodes[pivot].left=root as i32;nodes[root].right=middle;update(nodes,root);update(nodes,pivot);pivot}
fn insert(nodes:&mut [Node;MAX_NODES],root:i32,key:i64,next:&mut usize)->usize{if root<0{let i=*next;*next+=1;nodes[i]=Node{key,left:-1,right:-1,height:1};return i;}let r=root as usize;if key<nodes[r].key{let child=insert(nodes,nodes[r].left,key,next);nodes[r].left=child as i32;}else{let child=insert(nodes,nodes[r].right,key,next);nodes[r].right=child as i32;}update(nodes,r);let bf=h(nodes,nodes[r].left)-h(nodes,nodes[r].right);if bf>1{if key>nodes[nodes[r].left as usize].key{let c=rotate_left(nodes,nodes[r].left as usize);nodes[r].left=c as i32;}return rotate_right(nodes,r);}if bf < -1{if key<nodes[nodes[r].right as usize].key{let c=rotate_right(nodes,nodes[r].right as usize);nodes[r].right=c as i32;}return rotate_left(nodes,r);}r}
fn contains(nodes:&[Node;MAX_NODES],mut root:i32,key:i64)->bool{while root>=0{let i=root as usize;if nodes[i].key==key{return true;}root=if key<nodes[i].key{nodes[i].left}else{nodes[i].right};}false}
unsafe fn put(out:*mut u8,off:usize,v:i64){for(b,x)in v.to_le_bytes().iter().enumerate(){*out.add(off+b)=*x;}}
#[no_mangle]
pub unsafe extern "C" fn avl_tree_ruby_unique_key_insert_search(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<1{return -1;}let v=std::slice::from_raw_parts(input,length);let op_count=v[0];if !(0..=MAX_OPS as i64).contains(&op_count)||length!=1+2*op_count as usize{return -1;}
 let mut inserted=[0i64;MAX_NODES];let(mut ni,mut ns)=(0usize,0usize);
 for i in 0..op_count as usize{let(op,key)=(v[1+2*i],v[2+2*i]);if(op!=0&&op!=1)||!(-1_000_000..=1_000_000).contains(&key){return -1;}if op==0{if ni>=MAX_NODES||inserted[..ni].contains(&key){return -1;}inserted[ni]=key;ni+=1;}else{ns+=1;}}
 let mut nodes=[Node{key:0,left:-1,right:-1,height:0};MAX_NODES];let(mut root,mut next)=(-1i32,0usize);let mut results=[0i64;MAX_OPS];let mut q=0;
 for i in 0..op_count as usize{let(op,key)=(v[1+2*i],v[2+2*i]);if op==0{root=insert(&mut nodes,root,key,&mut next) as i32;}else{results[q]=contains(&nodes,root,key) as i64;q+=1;}}
 let bytes=(2+ni+ns)*8;if output.is_null()||capacity<bytes{return -2;}put(output,0,ni as i64);let mut stack=[0usize;MAX_NODES];let(mut top,mut current,mut out)=(0usize,root,1usize);
 while current>=0||top>0{while current>=0{stack[top]=current as usize;top+=1;current=nodes[current as usize].left;}top-=1;let i=stack[top];put(output,out*8,nodes[i].key);out+=1;current=nodes[i].right;}
 put(output,out*8,ns as i64);out+=1;for result in results.iter().take(ns){put(output,out*8,*result);out+=1;}bytes as i64
}
