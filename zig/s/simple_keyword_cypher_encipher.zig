export fn simple_keyword_cypher_encipher(v: [*c]const i64,n: usize,out: [*c]u8,cap: usize) i64 {
 if(v==null or n<2 or n>323)return -1;const kl=v[0];const ml=v[1];if(kl<0 or kl>64 or ml<0 or ml>256 or n!=2+@as(usize,@intCast(kl+ml)))return -1;
 var key=[_]u8{0}**26;var count:usize=0;for(0..@as(usize,@intCast(kl)))|i|{const x=v[2+i];if(!((x>=65 and x<=90)or(x>=97 and x<=122)))return -1;const c:u8=@intCast(if(x>=97)x-32 else x);var found=false;for(0..count)|j|{if(key[j]==c)found=true;}if(!found){key[count]=c;count+=1;}}
 var map=[_]u8{0}**26;var k:usize=0;for(0..count)|i|{map[k]=key[i];k+=1;}for(65..91)|x|{var found=false;for(0..count)|j|{if(key[j]==x)found=true;}if(!found){map[k]=@intCast(x);k+=1;}}
 var result=[_]u8{0}**256;for(0..@as(usize,@intCast(ml)))|i|{const x=v[2+@as(usize,@intCast(kl))+i];if(x<0 or x>127)return -1;const c:u8=@intCast(if(x>=97 and x<=122)x-32 else x);if(c>=65 and c<=90){result[i]=map[@as(usize,@intCast(c-65))];}else result[i]=c;}
 if(out==null or cap<@as(usize,@intCast(ml)))return -2;for(0..@as(usize,@intCast(ml)))|i|out[i]=result[i];return ml;
}
