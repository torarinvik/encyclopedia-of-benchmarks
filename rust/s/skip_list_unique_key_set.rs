const MAX_OPS:usize=128;
const MAX_LEVELS:usize=8;
const MIN_KEY:i64=-2147483647;
const MAX_KEY:i64=2147483646;
#[derive(Clone,Copy)]
struct Node{key:i64,value:i64,next:[usize;MAX_LEVELS]}
const EMPTY:Node=Node{key:0,value:0,next:[0;MAX_LEVELS]};
fn random_level(state:&mut u32)->usize{let mut level=1;loop{*state^=*state<<13;*state^=*state>>17;*state^=*state<<5;if(*state&1)!=0||level==MAX_LEVELS{return level;}level+=1;}}
fn find_update(nodes:&[Node;MAX_OPS+1],active:usize,key:i64,update:&mut[usize;MAX_LEVELS])->usize{let mut current=0;for level in (0..active).rev(){while nodes[current].next[level]!=0&&nodes[nodes[current].next[level]].key<key{current=nodes[current].next[level];}update[level]=current;}nodes[current].next[0]}
fn contains(nodes:&[Node;MAX_OPS+1],active:usize,key:i64)->bool{let mut update=[0;MAX_LEVELS];let found=find_update(nodes,active,key,&mut update);found!=0&&nodes[found].key==key}
fn insert(nodes:&mut[Node;MAX_OPS+1],next:&mut usize,active:&mut usize,rng:&mut u32,key:i64){let mut update=[0;MAX_LEVELS];let _=find_update(nodes,*active,key,&mut update);let height=random_level(rng);if height>*active{for item in update.iter_mut().take(height).skip(*active){*item=0;}*active=height;}let id=*next;*next+=1;nodes[id].key=key;nodes[id].value=key;for level in 0..height{nodes[id].next[level]=nodes[update[level]].next[level];nodes[update[level]].next[level]=id;}}
fn erase(nodes:&mut[Node;MAX_OPS+1],active:usize,key:i64)->bool{let mut update=[0;MAX_LEVELS];let found=find_update(nodes,active,key,&mut update);if found==0||nodes[found].key!=key{return false;}for level in 0..active{if nodes[update[level]].next[level]==found{nodes[update[level]].next[level]=nodes[found].next[level];}}true}

#[no_mangle]
pub unsafe extern "C" fn skip_list_unique_key_set(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<1{return -1;}let values=std::slice::from_raw_parts(input,length);
    if values[0]<0||values[0]>MAX_OPS as i64||length!=1+2*values[0] as usize{return -1;}let ops=values[0] as usize;
    for i in 0..ops{let op=values[1+2*i];let key=values[2+2*i];if !(0..=2).contains(&op)||!(MIN_KEY..=MAX_KEY).contains(&key){return -1;}}
    let mut nodes=[EMPTY;MAX_OPS+1];let(mut next,mut active,mut rng)=(1,1,0x9e3779b9_u32);
    for i in 0..ops{let op=values[1+2*i];let key=values[2+2*i];if op==0{if contains(&nodes,active,key){return -1;}insert(&mut nodes,&mut next,&mut active,&mut rng,key);}else if op==1{let _=contains(&nodes,active,key);}else if !erase(&mut nodes,active,key){return -1;}}
    let mut count=0;let mut id=nodes[0].next[0];while id!=0{count+=1;id=nodes[id].next[0];}let required=count*8;if output.is_null()||capacity<required{return -2;}
    let mut index=0;id=nodes[0].next[0];while id!=0{for byte in 0..8{*output.add(index*8+byte)=(nodes[id].value as u64>>(8*byte))as u8;}index+=1;id=nodes[id].next[0];}required as i64
}
