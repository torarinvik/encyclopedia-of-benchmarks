package skip_list_unique_key_set

import "core:c"

MAX_OPS :: 128
MAX_LEVELS :: 8
MIN_KEY :: i64(-2147483647)
MAX_KEY :: i64(2147483646)
Node :: struct { key,value:i64, level:int, next:[MAX_LEVELS]int }
random_level :: proc "contextless" (state:^u32)->int{level:=1;for level<MAX_LEVELS{state^ = (state^) ^ ((state^) << 13);state^ = (state^) ^ ((state^) >> 17);state^ = (state^) ^ ((state^) << 5);if((state^)&1)!=0{break};level+=1};return level}
find_update :: proc "contextless" (nodes:[^]Node,active:int,key:i64,update:^int)->int{current:=0;for level:=active-1;level>=0;level-=1{for nodes[current].next[level]!=0&&nodes[nodes[current].next[level]].key<key{current=nodes[current].next[level]};update[level]=current};return nodes[current].next[0]}
contains :: proc "contextless" (nodes:[^]Node,active:int,key:i64)->bool{var update:[MAX_LEVELS]int;found:=find_update(nodes,active,key,&update[0]);return found!=0&&nodes[found].key==key}
insert :: proc "contextless" (nodes:[^]Node,next:^int,active:^int,rng:^u32,key:i64){var update:[MAX_LEVELS]int;_ = find_update(nodes,active^,key,&update[0]);height:=random_level(rng);if height>active^{for level:=active^;level<height;level+=1{update[level]=0};active^=height};id:=next^;next^+=1;nodes[id].key=key;nodes[id].value=key;nodes[id].level=height;for level:=0;level<height;level+=1{nodes[id].next[level]=nodes[update[level]].next[level];nodes[update[level]].next[level]=id}}
erase :: proc "contextless" (nodes:[^]Node,active:int,key:i64)->bool{var update:[MAX_LEVELS]int;found:=find_update(nodes,active,key,&update[0]);if found==0||nodes[found].key!=key{return false};for level:=0;level<active;level+=1{if nodes[update[level]].next[level]==found{nodes[update[level]].next[level]=nodes[found].next[level]}};return true}
put_i64 :: proc "contextless" (output:[^]u8,offset:usize,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[offset+usize(b)]=u8(bits>>(8*b))}}

@(export)
skip_list_unique_key_set :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<1||input[0]<0||input[0]>MAX_OPS||length!=c.size_t(1+2*input[0]) do return -1
	ops:=int(input[0]);for i:=0;i<ops;i+=1{op,key:=input[1+2*i],input[2+2*i];if op<0||op>2||key<MIN_KEY||key>MAX_KEY do return -1}
	var nodes:[MAX_OPS+1]Node;next:=1;active:=1;rng:=u32(0x9e3779b9)
	for i:=0;i<ops;i+=1{op,key:=input[1+2*i],input[2+2*i];if op==0{if contains(&nodes[0],active,key) do return -1;insert(&nodes[0],&next,&active,&rng,key)}else if op==1{_ = contains(&nodes[0],active,key)}else if !erase(&nodes[0],active,key){return -1}}
	count:=0;for id:=nodes[0].next[0];id!=0;id=nodes[id].next[0]{count++};required:=count*8;if output==nil||capacity<c.size_t(required) do return -2
	index:=0;for id:=nodes[0].next[0];id!=0;id=nodes[id].next[0]{put_i64(output,usize(index*8),nodes[id].value);index++};return i64(required)
}
