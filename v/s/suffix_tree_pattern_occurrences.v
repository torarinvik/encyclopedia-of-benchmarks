module suffix_tree_pattern_occurrences
struct Node {mut:start int;mut:length int;mut:suffix int;mut:child_count int;mut:children [51]int}
fn code_at(input &i64,n int,p int)i64{if p==n{return -1};unsafe{return input[1+p]}}
fn put64(output &u8,pos int,value i64){bits:=u64(value);unsafe{for j in 0..8{output[pos+j]=u8((bits>>(8*j))&255)}}}
fn suffix_less(input &i64,n int,a int,b int)bool{mut p:=0;for a+p<=n&&b+p<=n{x:=code_at(input,n,a+p);y:=code_at(input,n,b+p);if x!=y{return x<y};p++};return a<b}
@[export: 'suffix_tree_pattern_occurrences']
pub fn suffix_tree_pattern_occurrences(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<3||length>39{return -1};nr:=input[0];if nr<0||nr>24{return -1};n:=int(nr);if int(length)<2+n{return -1};mr:=input[1+n];if mr<1||mr>12||int(length)!=2+n+int(mr){return -1};m:=int(mr)
  for i in 0..n{if input[1+i]<0||input[1+i]>127{return -1}};for i in 0..m{if input[2+n+i]<0||input[2+n+i]>127{return -1}}
  mut nodes:=[51]Node{};mut node_count:=1
  for start in 0..(n+1){suffix_len:=n+1-start;mut off:=0;mut node:=0;for off<suffix_len{first:=code_at(input,n,start+off);mut slot:=0;for slot<nodes[node].child_count&&code_at(input,n,nodes[nodes[node].children[slot]].start)!=first{slot++};if slot==nodes[node].child_count{if node_count>=51{return -1};leaf:=node_count;node_count++;nodes[leaf].start=start+off;nodes[leaf].length=suffix_len-off;nodes[leaf].suffix=start;nodes[node].children[nodes[node].child_count]=leaf;nodes[node].child_count++;break};child:=nodes[node].children[slot];mut common:=0;for common<nodes[child].length&&off+common<suffix_len&&code_at(input,n,start+off+common)==code_at(input,n,nodes[child].start+common){common++};if common==nodes[child].length{off+=common;node=child;continue};if node_count>=51{return -1};split:=node_count;node_count++;nodes[split].start=nodes[child].start;nodes[split].length=common;nodes[split].children[0]=child;nodes[split].child_count=1;nodes[child].start+=common;nodes[child].length-=common;nodes[node].children[slot]=split;off+=common;node=split}}
  mut node:=0;mut off:=0;mut matched:=false;for off<m{wanted:=input[2+n+off];mut slot:=0;for slot<nodes[node].child_count&&code_at(input,n,nodes[nodes[node].children[slot]].start)!=wanted{slot++};if slot==nodes[node].child_count{break};child:=nodes[node].children[slot];mut common:=0;for common<nodes[child].length&&off+common<m&&code_at(input,n,nodes[child].start+common)==input[2+n+off+common]{common++};if off+common==m{node=child;matched=true;break};if common!=nodes[child].length{break};off+=common;node=child}
  mut starts:=[24]int{};mut count:=0;if matched{mut stack:=[51]int{};mut top:=1;stack[0]=node;for top>0{top--;x:=stack[top];if nodes[x].child_count==0&&nodes[x].length>0{starts[count]=nodes[x].suffix;count++};for j in 0..nodes[x].child_count{stack[top]=nodes[x].children[j];top++}}}
  for i in 1..count{x:=starts[i];mut j:=i;for j>0&&suffix_less(input,n,x,starts[j-1]){starts[j]=starts[j-1];j--};starts[j]=x}
  bytes:=8*(1+count);if output==nil||capacity<usize(bytes){return -2};put64(output,0,i64(count));for i in 0..count{put64(output,8+8*i,i64(starts[i]))};return i64(bytes)
 }
}
