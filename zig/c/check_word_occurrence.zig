const MAX_INPUT:usize=1024;const MAX_ENTRIES:usize=1025;
fn ws(c:u8)bool{return (c>=9 and c<=13) or c==32;}
fn lower(c:u8)u8{return if(c>='A' and c<='Z') c+32 else c;}
fn forbidden(text:[*]const u8,start:usize,n:usize)bool{const names=[_] []const u8{"constructor","tostring","tolocalestring","valueof","hasownproperty","isprototypeof","propertyisenumerable"};for(names)|name|{if(n==name.len){var i:usize=0;while(i<n and lower(text[start+i])==name[i]) : (i+=1) {} if(i==n)return true;}}return false;}
fn put32(out:[*]u8,pos:*usize,x:u32)void{var bits=x;for(0..4)|_|{out[pos.*]=@truncate(bits);pos.*+=1;bits>>=8;}}
pub export fn check_word_occurrence(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<2)return -1;if(input[0]<0 or input[0]>1 or input[1]<0 or input[1]>MAX_INPUT or length!=@as(usize,@intCast(input[1]))+2)return -1;const n:usize=@intCast(input[1]);var text:[MAX_INPUT]u8=@splat(0);
 for(0..n)|i|{const x=input[i+2];if(x<0 or x>127)return -1;const c:u8=@intCast(x);if(!((c>='A' and c<='Z') or (c>='a' and c<='z') or ws(c)))return -1;text[i]=if(input[0]==1)lower(c) else c;}
 var starts:[MAX_ENTRIES]usize=@splat(0);var lens:[MAX_ENTRIES]usize=@splat(0);var counts:[MAX_ENTRIES]u32=@splat(0);var entries:usize=0;var i:usize=0;var start:usize=0;
 while(true){if(i==n or ws(text[i])){const size=i-start;if(forbidden(&text,start,size))return -1;var j:usize=0;while(j<entries){if(lens[j]==size){var q:usize=0;while(q<size and text[starts[j]+q]==text[start+q]) : (q+=1) {}if(q==size)break;}j+=1;}if(j==entries){starts[j]=start;lens[j]=size;entries+=1;}counts[j]+=1;if(i==n)break;while(i<n and ws(text[i])) : (i+=1) {}start=i;}else{i+=1;}}
 var need:usize=4;for(0..entries)|j|{need+=8+lens[j];}if(capacity<need or output==null)return -2;var pos:usize=0;put32(output,&pos,@intCast(entries));for(0..entries)|j|{put32(output,&pos,@intCast(lens[j]));for(0..lens[j])|q|{output[pos]=text[starts[j]+q];pos+=1;}put32(output,&pos,counts[j]);}return @intCast(pos);
}
