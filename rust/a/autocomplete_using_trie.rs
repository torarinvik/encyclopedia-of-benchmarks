const W:usize=32;const L:usize=16;const Q:usize=16;const NN:usize=1+W*L;const NO:usize=1+Q*(1+W*(1+L));
#[derive(Clone,Copy)]struct Node{child:[i16;26],terminal:bool}
const EMPTY:Node=Node{child:[-1;26],terminal:false};
fn collect(nodes:&[Node;NN],at:usize,path:&mut[usize;L],depth:usize,out:&mut[i64;NO],used:&mut usize,count:&mut usize){if nodes[at].terminal{out[*used]=depth as i64;*used+=1;for j in 0..depth{out[*used]=(b'a'+path[j] as u8)as i64;*used+=1;}*count+=1;}for c in 0..26{let child=nodes[at].child[c];if child>=0{path[depth]=c;collect(nodes,child as usize,path,depth+1,out,used,count);}}}
unsafe fn put(out:*mut u8,index:usize,value:i64){let bits=value as u64;for b in 0..8{*out.add(index*8+b)=(bits>>(8*b))as u8;}}
#[no_mangle]
pub unsafe extern "C" fn autocomplete_using_trie(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2{return -1;}let x=std::slice::from_raw_parts(input,length);if x[0]<0||x[0]>W as i64{return -1;}let mut nodes=[EMPTY;NN];let mut nc=1usize;let mut pos=1usize;
 for _ in 0..x[0] as usize{if pos>=length{return -1;}let lv=x[pos];pos+=1;if lv<1||lv>L as i64||pos+lv as usize>length{return -1;}let mut at=0usize;for _ in 0..lv{let ch=x[pos];pos+=1;if ch<97||ch>122{return -1;}let c=(ch-97)as usize;if nodes[at].child[c]<0{if nc>=NN{return -1;}nodes[nc]=EMPTY;nodes[at].child[c]=nc as i16;nc+=1;}at=nodes[at].child[c]as usize;}nodes[at].terminal=true;}
 if pos>=length{return -1;}let qv=x[pos];pos+=1;if qv<0||qv>Q as i64{return -1;}let q=qv as usize;let mut qp=[0usize;Q];let mut ql=[0usize;Q];for i in 0..q{if pos>=length{return -1;}let lv=x[pos];pos+=1;if lv<0||lv>L as i64||pos+lv as usize>length{return -1;}qp[i]=pos;ql[i]=lv as usize;for j in 0..ql[i]{if x[pos+j]<97||x[pos+j]>122{return -1;}}pos+=ql[i];}if pos!=length{return -1;}
 let mut vals=[0i64;NO];let mut used=0usize;vals[used]=q as i64;used+=1;for i in 0..q{let mut at=0usize;let mut path=[0usize;L];let mut found=true;for j in 0..ql[i]{let c=(x[qp[i]+j]-97)as usize;path[j]=c;if nodes[at].child[c]<0{found=false;break;}at=nodes[at].child[c]as usize;}let cp=used;used+=1;let mut count=0usize;if found{collect(&nodes,at,&mut path,ql[i],&mut vals,&mut used,&mut count);}vals[cp]=count as i64;}let required=used*8;if output.is_null()||capacity<required{return -2;}for i in 0..used{put(output,i,vals[i]);}required as i64
}
