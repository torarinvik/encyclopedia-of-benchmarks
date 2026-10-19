package nbench_huffman_compression
import "core:c"
// BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
// Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE.
MAX_TEXT :: 128
MAX_STREAM_BYTES :: 258
EXCLUDED :: 32000
Huff_Node :: struct { c:u8, freq:f32, parent:int, left:int, right:int }
put_u32 :: proc(out:[^]u8,x:u32){for i:=0;i<4;i+=1{out[i]=u8(x>>u32(8*i))}}

@(export)
nbench_huffman_compression :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<2||length>MAX_TEXT+1 do return -1;raw_n:=input[0];if raw_n<1||raw_n>MAX_TEXT||length!=c.size_t(raw_n+1) do return -1;n:=int(raw_n);array_size:=n+1
 text:[MAX_TEXT+1]u8 = {};seen:[256]bool = {};distinct:=0;for i:=0;i<n;i+=1{if input[i+1]<32||input[i+1]>47 do return -1;text[i]=u8(input[i+1]);if !seen[int(text[i])]{seen[int(text[i])]=true;distinct++}};text[n]=0;if !seen[0]{distinct++};if distinct<2 do return -1
 tree:[512]Huff_Node = {};for i:=0;i<256;i+=1{tree[i]=Huff_Node{u8(i),0,-1,-1,-1}};for i:=0;i<array_size;i+=1{tree[int(text[i])].freq+=1};for i:=0;i<256;i+=1{if tree[i].freq!=0{tree[i].freq/=f32(array_size)}};for i:=256;i<512;i+=1{tree[i]=Huff_Node{0,0,EXCLUDED,0,0}};for i:=0;i<512;i+=1{if tree[i].freq==0{tree[i].parent=EXCLUDED}else{tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1}}
 root:=255;for{low1:f32=2;low2:f32=2;idx1:=-1;idx2:=-1;for i:=0;i<=root;i+=1{if tree[i].parent<0&&tree[i].freq<low1{low1=tree[i].freq;idx1=i}};if idx1<0{break};for i:=0;i<=root;i+=1{if tree[i].parent<0&&i!=idx1&&tree[i].freq<low2{low2=tree[i].freq;idx2=i}};if idx2<0{break};root++;tree[idx1].parent=root;tree[idx2].parent=root;tree[root].freq=low1+low2;tree[root].left=idx1;tree[root].right=idx2;tree[root].parent=-2};if root<256||tree[root].left<0 do return -1
 stream:[MAX_STREAM_BYTES]u8 = {};bit_count:=0;for i:=0;i<array_size;i+=1{path:[30]int = {};count:=0;node:=int(text[i]);for tree[node].parent!=-2{parent:=tree[node].parent;if parent<0||parent>=512||count>=30 do return -1;path[count]=0;if tree[parent].left!=node{path[count]=1};count++;node=parent};for count>0{count--;if path[count]!=0{stream[bit_count/8]|=u8(1<<u32(bit_count%8))};bit_count++}}
 decoded:[MAX_TEXT+1]u8 = {};bit:=0;pos:=0;for bit<bit_count{node:=root;for tree[node].left!=-1{b:=(stream[bit/8]>>u32(bit%8))&1;if b==0{node=tree[node].left}else{node=tree[node].right};bit++;if bit>bit_count do return -1};if pos>=array_size do return -1;decoded[pos]=tree[node].c;pos++};if pos!=array_size do return -1;for i:=0;i<array_size;i+=1{if decoded[i]!=text[i] do return -1}
 stream_bytes:=(bit_count+7)/8;total:=4+stream_bytes;if output==nil||capacity<c.size_t(total) do return -2;put_u32(output,u32(bit_count));for i:=0;i<stream_bytes;i+=1{output[4+i]=stream[i]};return i64(total)
}
