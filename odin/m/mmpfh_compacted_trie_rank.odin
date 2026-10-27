package mmpfh_compacted_trie_rank
import "core:c"
K :: 16
Q :: 16
NN :: 31
OUT :: 174
Node :: struct { bit: int, left: int, right: int, leaves: int, key: u32, low: u32, high: u32 }
keys: [K]u32
nodes: [NN]Node
node_count: int
build :: proc(lo, hi, width: int) -> int {
 id:=node_count; node_count+=1
 if hi-lo==1 { nodes[id]=Node{-1,-1,-1,1,keys[lo],keys[lo],keys[lo]};return id }
 diff:=keys[lo]^keys[hi-1];bit:=width-1
 for ((diff>>bit)&1)==0 { bit-=1 }
 split:=lo;for split<hi && ((keys[split]>>bit)&1)==0 { split+=1 }
 nodes[id].bit=width-1-bit;nodes[id].key=0;nodes[id].low=keys[lo];nodes[id].high=keys[hi-1]
 nodes[id].left=build(lo,split,width);nodes[id].right=build(split,hi,width)
 nodes[id].leaves=nodes[nodes[id].left].leaves+nodes[nodes[id].right].leaves
 return id
}
rank_key :: proc(q: u32,width: int)->int {
 id:=0;rank:=0
 for true {if q<nodes[id].low{return rank};if q>nodes[id].high{return rank+nodes[id].leaves};if nodes[id].bit<0{return rank};sh:=width-1-nodes[id].bit;if ((q>>sh)&1)!=0 {rank+=nodes[nodes[id].left].leaves;id=nodes[id].right}else{id=nodes[id].left} }
}
put_i64 :: proc(out: [^]u8,pos: int,value: i64) { bits:=u64(value);for b in 0..<8 {out[pos+b]=u8((bits>>(8*b))&255)} }
@(export)
mmpfh_compacted_trie_rank :: proc "c" (input: [^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<3||length>35 do return -1
 w0:=input[0];d0:=input[1];q0:=input[2]
 if w0<1||w0>16||d0<1||d0>K||q0<1||q0>Q||length!=c.size_t(3+d0+q0) do return -1
 limit:=u32(1)<<u32(w0)
 for i in 0..<int(d0) {x:=input[3+i];if x<0||u64(x)>=u64(limit)||(i>0&&x<=input[2+i]) do return -1;keys[i]=u32(x)}
 for i in 0..<int(q0) {x:=input[3+int(d0)+i];if x<0||u64(x)>=u64(limit) do return -1}
 node_count=0;build(0,int(d0),int(w0))
 staged:[OUT]i64;used:=0;staged[used]=d0;used+=1;staged[used]=i64(node_count);used+=1;staged[used]=q0;used+=1
 for i in 0..<node_count {nd:=nodes[i];staged[used]=i64(nd.bit);used+=1;staged[used]=i64(nd.left);used+=1;staged[used]=i64(nd.right);used+=1;staged[used]=i64(nd.low);used+=1;staged[used]=i64(nd.high);used+=1}
 for i in 0..<int(q0) {staged[used]=i64(rank_key(u32(input[3+int(d0)+i]),int(w0)));used+=1}
 required:=used*8;if output==nil||capacity<c.size_t(required) do return -2
 for i in 0..<used {put_i64(output,i*8,staged[i])};return i64(required)
}
