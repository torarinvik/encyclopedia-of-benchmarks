// BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
// Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE.
const MAX_TEXT: usize = 128;
const MAX_STREAM_BYTES: usize = 258;
const EXCLUDED: i32 = 32000;
#[derive(Clone, Copy)] struct HuffNode { c:u8, freq:f32, parent:i32, left:i32, right:i32 }
#[no_mangle]
pub unsafe extern "C" fn nbench_huffman_compression(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>MAX_TEXT+1{return -1;}let v=std::slice::from_raw_parts(input,length);let raw=v[0];if raw<1||raw>MAX_TEXT as i64||length!=raw as usize+1{return -1;}let n=raw as usize;let arraysize=n+1;
 let mut text=[0u8;MAX_TEXT+1];let mut seen=[false;256];let mut distinct=0usize;for i in 0..n{if v[i+1]<32||v[i+1]>47{return -1;}text[i]=v[i+1] as u8;if !seen[text[i] as usize]{seen[text[i] as usize]=true;distinct+=1;}}text[n]=0;if !seen[0]{distinct+=1;}if distinct<2{return -1;}
 let mut tree=[HuffNode{c:0,freq:0.0,parent:EXCLUDED,left:0,right:0};512];for i in 0..256{tree[i].c=i as u8;tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1;}for j in 0..arraysize{let x=text[j] as usize;tree[x].freq+=1.0f32;}for i in 0..256{if tree[i].freq!=0.0{tree[i].freq=tree[i].freq/(arraysize as f32);}}for i in 0..512{if tree[i].freq==0.0{tree[i].parent=EXCLUDED;}else{tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1;}}
 let mut root=255i32;loop{let(mut low1,mut low2)=(2.0f32,2.0f32);let(mut idx1,mut idx2)=(-1i32,-1i32);for i in 0..=root{let u=i as usize;if tree[u].parent<0&&tree[u].freq<low1{low1=tree[u].freq;idx1=i;}}if idx1<0{break;}for i in 0..=root{let u=i as usize;if tree[u].parent<0&&i!=idx1&&tree[u].freq<low2{low2=tree[u].freq;idx2=i;}}if idx2<0{break;}root+=1;tree[idx1 as usize].parent=root;tree[idx2 as usize].parent=root;tree[root as usize].freq=low1+low2;tree[root as usize].left=idx1;tree[root as usize].right=idx2;tree[root as usize].parent=-2;}
 if root<256||tree[root as usize].left<0{return -1;}let mut stream=[0u8;MAX_STREAM_BYTES];let mut bit_count=0usize;for j in 0..arraysize{let mut path=[0i32;30];let mut count=0usize;let mut node=text[j] as usize;while tree[node].parent!=-2{let p=tree[node].parent;if p<0||p>=512||count>=30{return -1;}path[count]=if tree[p as usize].left==node as i32{0}else{1};count+=1;node=p as usize;}while count>0{count-=1;if path[count]!=0{stream[bit_count>>3]|=1<<(bit_count&7);}bit_count+=1;}}
 let mut decoded=[0u8;MAX_TEXT+1];let(mut bit,mut pos)=(0usize,0usize);while bit<bit_count{let mut node=root;while tree[node as usize].left!=-1{let b=(stream[bit>>3]>>(bit&7))&1;node=if b==0{tree[node as usize].left}else{tree[node as usize].right};bit+=1;if bit>bit_count{return -1;}}if pos>=arraysize{return -1;}decoded[pos]=tree[node as usize].c;pos+=1;}if pos!=arraysize||decoded[..arraysize]!=text[..arraysize]{return -1;}
 let stream_bytes=(bit_count+7)/8;let total=4+stream_bytes;if output.is_null()||capacity<total{return -2;}let bits=bit_count as u32;for b in 0..4{*output.add(b)=(bits>>(8*b)) as u8;}for i in 0..stream_bytes{*output.add(4+i)=stream[i];}total as i64
}
