/// Return access events and the final cache ordered from MRU to LRU.
fn putI64Le(out:[*]u8,index:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[index*8+b]=@truncate(bits>>@intCast(8*b));}
pub export fn lru_page_reference(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<2)return -1;const cv=input[0];const nv=input[1];if(cv<1 or cv>64 or (cv&(cv-1))!=0 or nv<0 or nv>256)return -1;const c:usize=@intCast(cv);const n:usize=@intCast(nv);if(length!=n+2)return -1;
 const pages=input[2..][0..n];for(pages)|p|if(p<0 or p>1_000_000)return -1;
 var cache:[64]i64=@splat(0);var events:[512]i64=@splat(0);var used:usize=0;
 for(0..n)|i|{const page=pages[i];var evicted:i64=-1;var p:usize=0;while(p<used and cache[p]!=page):(p+=1){}if(p<used){var j=p;while(j>0){cache[j]=cache[j-1];j-=1;}cache[0]=page;events[2*i]=1;}else{if(used==c){evicted=cache[used-1];used-=1;}var j=used;while(j>0){cache[j]=cache[j-1];j-=1;}cache[0]=page;used+=1;events[2*i]=0;}events[2*i+1]=evicted;}
 const words=2*n+2+used;if(output==null or capacity<words*8)return -2;var k:usize=0;putI64Le(output,k,@intCast(n));k+=1;for(events[0..2*n])|v|{putI64Le(output,k,v);k+=1;}putI64Le(output,k,@intCast(used));k+=1;for(cache[0..used])|v|{putI64Le(output,k,v);k+=1;}return @intCast(words*8);
}
