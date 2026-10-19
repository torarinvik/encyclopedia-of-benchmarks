module nbench_huffman_compression
// BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
// Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE.
const max_text = 128
const max_stream_bytes = 258
const excluded = 32000
struct HuffNode { mut: c u8 freq f32 parent int left int right int }
fn put_u32(out &u8,x u32){unsafe{for i in 0..4{out[i]=u8(x>>u32(8*i))}}}

@[export: 'nbench_huffman_compression']
pub fn nbench_huffman_compression(input &i64,length usize,output &u8,capacity usize) i64 {
 unsafe {
 if input==nil||length<2||length>max_text+1{return -1};raw_n:=input[0];if raw_n<1||raw_n>max_text||length!=usize(raw_n+1){return -1};n:=int(raw_n);array_size:=n+1
 mut text:=[max_text+1]u8{init:0};mut seen:=[256]bool{init:false};mut distinct:=0
 for i in 0..n{if input[i+1]<32||input[i+1]>47{return -1};text[i]=u8(input[i+1]);if !seen[int(text[i])]{seen[int(text[i])]=true;distinct++}};text[n]=0;if !seen[0]{distinct++};if distinct<2{return -1}
 mut tree:=[512]HuffNode{init:HuffNode{}};for i in 0..256{tree[i]=HuffNode{c:u8(i),freq:0,parent:-1,left:-1,right:-1}};for i in 0..array_size{tree[int(text[i])].freq+=1.0};for i in 0..256{if tree[i].freq!=0{tree[i].freq=tree[i].freq/f32(array_size)}};for i in 256..512{tree[i]=HuffNode{c:0,freq:0,parent:excluded,left:0,right:0}};for i in 0..512{if tree[i].freq==0{tree[i].parent=excluded}else{tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1}}
 mut root:=255;for{mut low1:=f32(2);mut low2:=f32(2);mut idx1:=-1;mut idx2:=-1;for i in 0..root+1{if tree[i].parent<0&&tree[i].freq<low1{low1=tree[i].freq;idx1=i}};if idx1<0{break};for i in 0..root+1{if tree[i].parent<0&&i!=idx1&&tree[i].freq<low2{low2=tree[i].freq;idx2=i}};if idx2<0{break};root++;tree[idx1].parent=root;tree[idx2].parent=root;tree[root].freq=low1+low2;tree[root].left=idx1;tree[root].right=idx2;tree[root].parent=-2};if root<256||tree[root].left<0{return -1}
 mut stream:=[max_stream_bytes]u8{init:0};mut bit_count:=0;for i in 0..array_size{mut path:=[30]int{init:0};mut count:=0;mut node:=int(text[i]);for tree[node].parent!=-2{parent:=tree[node].parent;if parent<0||parent>=512||count>=30{return -1};path[count]=if tree[parent].left==node{0}else{1};count++;node=parent};for count>0{count--;if path[count]!=0{stream[bit_count/8]|=u8(1<<u32(bit_count%8))};bit_count++}}
 mut decoded:=[max_text+1]u8{init:0};mut bit:=0;mut pos:=0;for bit<bit_count{mut node:=root;for tree[node].left!=-1{b:=(stream[bit/8]>>u32(bit%8))&1;node=if b==0{tree[node].left}else{tree[node].right};bit++;if bit>bit_count{return -1}};if pos>=array_size{return -1};decoded[pos]=tree[node].c;pos++};if pos!=array_size{return -1};for i in 0..array_size{if decoded[i]!=text[i]{return -1}}
 stream_bytes:=(bit_count+7)/8;total:=4+stream_bytes;if output==nil||capacity<usize(total){return -2};put_u32(output,u32(bit_count));for i in 0..stream_bytes{output[4+i]=stream[i]};return i64(total)
 }
}
