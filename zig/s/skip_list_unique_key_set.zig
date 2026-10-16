const MAX_OPS:usize=128;
const MAX_LEVELS:usize=8;
const MIN_KEY:i64=-2147483647;
const MAX_KEY:i64=2147483646;
const Node=struct{key:i64,value:i64,level:usize,next:[MAX_LEVELS]usize};
const EMPTY=Node{.key=0,.value=0,.level=0,.next=[_]usize{0}**MAX_LEVELS};

fn randomLevel(state:*u32)usize{var level:usize=1;while(level<MAX_LEVELS){state.* = state.* ^ (state.* << 13);state.* = state.* ^ (state.* >> 17);state.* = state.* ^ (state.* << 5);if((state.*&1)!=0)break;level+=1;}return level;}
fn findUpdate(nodes:[]Node,active:usize,key:i64,update:*[MAX_LEVELS]usize)usize{var current:usize=0;var level=active;while(level>0){level-=1;while(nodes[current].next[level]!=0 and nodes[nodes[current].next[level]].key<key){current=nodes[current].next[level];}update[level]=current;}return nodes[current].next[0];}
fn contains(nodes:[]Node,active:usize,key:i64)bool{var update=[_]usize{0}**MAX_LEVELS;const found=findUpdate(nodes,active,key,&update);return found!=0 and nodes[found].key==key;}
fn insert(nodes:[]Node,next:*usize,active:*usize,rng:*u32,key:i64)void{var update=[_]usize{0}**MAX_LEVELS;_=findUpdate(nodes,active.*,key,&update);const height=randomLevel(rng);if(height>active.*){for(active.* .. height)|level|update[level]=0;active.*=height;}const id=next.*;next.*+=1;nodes[id].key=key;nodes[id].value=key;nodes[id].level=height;for(0..height)|level|{nodes[id].next[level]=nodes[update[level]].next[level];nodes[update[level]].next[level]=id;}}
fn erase(nodes:[]Node,active:usize,key:i64)bool{var update=[_]usize{0}**MAX_LEVELS;const found=findUpdate(nodes,active,key,&update);if(found==0 or nodes[found].key!=key)return false;for(0..active)|level|{if(nodes[update[level]].next[level]==found)nodes[update[level]].next[level]=nodes[found].next[level];}return true;}

pub export fn skip_list_unique_key_set(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<1 or input[0]<0 or input[0]>@as(i64,@intCast(MAX_OPS)) or length!=1+2*@as(usize,@intCast(input[0])))return -1;
    const ops:usize=@intCast(input[0]);
    for(0..ops)|i|{const op=input[1+2*i];const key=input[2+2*i];if(op<0 or op>2 or key<MIN_KEY or key>MAX_KEY)return -1;}
    var nodes=[_]Node{EMPTY}**(MAX_OPS+1);var next:usize=1;var active:usize=1;var rng:u32=0x9e3779b9;
    for(0..ops)|i|{const op=input[1+2*i];const key=input[2+2*i];if(op==0){if(contains(nodes[0..],active,key))return -1;insert(nodes[0..],&next,&active,&rng,key);}else if(op==1){_=contains(nodes[0..],active,key);}else if(!erase(nodes[0..],active,key))return -1;}
    var count:usize=0;var id=nodes[0].next[0];while(id!=0){count+=1;id=nodes[id].next[0];}
    const required=count*8;if(output==null or capacity<required)return -2;
    var index:usize=0;id=nodes[0].next[0];while(id!=0){const bits:u64=@bitCast(nodes[id].value);for(0..8)|byte|output[index*8+byte]=@truncate(bits>>@intCast(8*byte));index+=1;id=nodes[id].next[0];}
    return @intCast(required);
}
