// BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
// Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE.
const MAX_TEXT: usize = 128;
const MAX_STREAM_BYTES: usize = 258;
const EXCLUDED: i32 = 32000;
const HuffNode = struct { c:u8=0, freq:f32=0, parent:i32=EXCLUDED, left:i32=0, right:i32=0 };
fn putU32(out:[*]u8,x:u32)void{for(0..4)|i|out[i]=@truncate(x>>@intCast(8*i));}

export fn nbench_huffman_compression(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
 if(input==null or length<2 or length>MAX_TEXT+1)return -1;const values=input.?;const raw_n=values[0];if(raw_n<1 or raw_n>MAX_TEXT or length!=@as(usize,@intCast(raw_n))+1)return -1;const n:usize=@intCast(raw_n);const array_size=n+1;
 var text:[MAX_TEXT+1]u8=@splat(0);var seen:[256]bool=@splat(false);var distinct:usize=0;for(0..n)|i|{const x=values[i+1];if(x<32 or x>47)return -1;text[i]=@intCast(x);if(!seen[text[i]]){seen[text[i]]=true;distinct+=1;}}text[n]=0;if(!seen[0])distinct+=1;if(distinct<2)return -1;
 var tree:[512]HuffNode=@splat(.{});for(0..256)|i|{tree[i].c=@intCast(i);tree[i].freq=0;tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1;}for(0..array_size)|i|{tree[text[i]].freq+=1.0;}for(0..256)|i|{if(tree[i].freq!=0)tree[i].freq=tree[i].freq/@as(f32,@floatFromInt(array_size));}for(256..512)|i|{tree[i]=.{.c=0,.freq=0,.parent=EXCLUDED,.left=0,.right=0};}for(0..512)|i|{if(tree[i].freq==0)tree[i].parent=EXCLUDED else{tree[i].parent=-1;tree[i].left=-1;tree[i].right=-1;}}
 var root:i32=255;while(true){var low1:f32=2.0;var low2:f32=2.0;var idx1:i32 = -1;var idx2:i32 = -1;var i:i32=0;while(i<=root):(i+=1){const u:usize=@intCast(i);if(tree[u].parent<0 and tree[u].freq<low1){low1=tree[u].freq;idx1=i;}}if(idx1<0)break;i=0;while(i<=root):(i+=1){const u:usize=@intCast(i);if(tree[u].parent<0 and i!=idx1 and tree[u].freq<low2){low2=tree[u].freq;idx2=i;}}if(idx2<0)break;root+=1;const r:usize=@intCast(root);tree[@intCast(idx1)].parent=root;tree[@intCast(idx2)].parent=root;tree[r].freq=low1+low2;tree[r].left=idx1;tree[r].right=idx2;tree[r].parent=-2;}if(root<256 or tree[@intCast(root)].left<0)return -1;
 var stream:[MAX_STREAM_BYTES]u8=@splat(0);var bit_count:usize=0;for(0..array_size)|i|{var path:[30]u8=@splat(0);var count:usize=0;var node:usize=text[i];while(tree[node].parent != -2){const par=tree[node].parent;if(par<0 or par>=512 or count>=30)return -1;path[count]=if(tree[@intCast(par)].left==@as(i32,@intCast(node))) 0 else 1;count+=1;node=@intCast(par);}while(count>0){count-=1;if(path[count]!=0)stream[bit_count>>3]|=@as(u8,1)<<@intCast(bit_count&7);bit_count+=1;}}
 var decoded:[MAX_TEXT+1]u8=@splat(0);var bit:usize=0;var pos:usize=0;while(bit<bit_count){var node:i32=root;while(tree[@intCast(node)].left != -1){const b=(stream[bit>>3]>>@intCast(bit&7))&1;node=if(b==0)tree[@intCast(node)].left else tree[@intCast(node)].right;bit+=1;if(bit>bit_count)return -1;}if(pos>=array_size)return -1;decoded[pos]=tree[@intCast(node)].c;pos+=1;}if(pos!=array_size)return -1;for(0..array_size)|i|{if(decoded[i]!=text[i])return -1;}
 const stream_bytes=(bit_count+7)/8;const total=4+stream_bytes;if(output==null or capacity<total)return -2;const out=output.?;putU32(out,@intCast(bit_count));for(0..stream_bytes)|i|out[4+i]=stream[i];return @intCast(total);
}
