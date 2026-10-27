package suffix_tree_pattern_occurrences
import "core:c"
MAX_NODES :: 51
MAX_INPUT :: 39
Node :: struct {start,length,suffix,child_count:int,children:[MAX_NODES]int}
code_at :: proc(input:[^]i64,n,p:int)->i64{if p==n{return -1};return input[1+p]}
put64 :: proc(output:[^]u8,pos:int,value:i64){bits:=u64(value);for j:=0;j<8;j+=1{output[pos+j]=u8(bits&255);bits>>=8}}
suffix_less :: proc(input:[^]i64,n,a,b:int)->bool{p:=0;for a+p<=n&&b+p<=n{ x:=code_at(input,n,a+p);y:=code_at(input,n,b+p);if x!=y{return x<y};p+=1 };return a<b}
@(export)
suffix_tree_pattern_occurrences :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>MAX_INPUT do return -1
 nr:=input[0];if nr<0||nr>24 do return -1;n:=int(nr);if int(length)<2+n do return -1
 mr:=input[1+n];if mr<1||mr>12||int(length)!=2+n+int(mr) do return -1;m:=int(mr)
 for i:=0;i<n;i+=1{if input[1+i]<0||input[1+i]>127 do return -1};for i:=0;i<m;i+=1{if input[2+n+i]<0||input[2+n+i]>127 do return -1}
 nodes:[MAX_NODES]Node;node_count:=1
 for start:=0;start<=n;start+=1{suffix_len:=n+1-start;off:=0;node:=0;for off<suffix_len{first:=code_at(input,n,start+off);slot:=0;for slot<nodes[node].child_count&&code_at(input,n,nodes[nodes[node].children[slot]].start)!=first{slot+=1};if slot==nodes[node].child_count{if node_count>=MAX_NODES do return -1;leaf:=node_count;node_count+=1;nodes[leaf].start=start+off;nodes[leaf].length=suffix_len-off;nodes[leaf].suffix=start;nodes[node].children[nodes[node].child_count]=leaf;nodes[node].child_count+=1;break};child:=nodes[node].children[slot];common:=0;for common<nodes[child].length&&off+common<suffix_len&&code_at(input,n,start+off+common)==code_at(input,n,nodes[child].start+common){common+=1};if common==nodes[child].length{off+=common;node=child;continue};if node_count>=MAX_NODES do return -1;split:=node_count;node_count+=1;nodes[split].start=nodes[child].start;nodes[split].length=common;nodes[split].children[0]=child;nodes[split].child_count=1;nodes[child].start+=common;nodes[child].length-=common;nodes[node].children[slot]=split;off+=common;node=split}}
 node:=0;off:=0;matched:=false;for off<m{wanted:=input[2+n+off];slot:=0;for slot<nodes[node].child_count&&code_at(input,n,nodes[nodes[node].children[slot]].start)!=wanted{slot+=1};if slot==nodes[node].child_count{break};child:=nodes[node].children[slot];common:=0;for common<nodes[child].length&&off+common<m&&code_at(input,n,nodes[child].start+common)==input[2+n+off+common]{common+=1};if off+common==m{node=child;matched=true;break};if common!=nodes[child].length{break};off+=common;node=child}
 starts:[24]int;count:=0;if matched{stack:[MAX_NODES]int;top:=1;stack[0]=node;for top>0{top-=1;x:=stack[top];if nodes[x].child_count==0&&nodes[x].length>0{starts[count]=nodes[x].suffix;count+=1};for j:=0;j<nodes[x].child_count;j+=1{stack[top]=nodes[x].children[j];top+=1}}}
 for i:=1;i<count;i+=1{x:=starts[i];j:=i;for j>0&&suffix_less(input,n,x,starts[j-1]){starts[j]=starts[j-1];j-=1};starts[j]=x}
 bytes:=8*(1+count);if output==nil||int(capacity)<bytes do return -2;put64(output,0,i64(count));for i:=0;i<count;i+=1{put64(output,8+8*i,i64(starts[i]))};return i64(bytes)
}
