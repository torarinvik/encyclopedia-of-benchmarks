const max_text:usize=32;const max_pattern:usize=8;const max_input:usize=43;const alphabet:usize=5;
fn lessSuffix(s:*const [33]i64,n:usize,a0:usize,b0:usize)bool{var a=a0;var b=b0;while(a<n and b<n){if(s[a]!=s[b])return s[a]<s[b];a+=1;b+=1;}return a==n and b!=n;}
fn store(out:[*]u8,off:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[off+b]=@truncate(bits>>@intCast(8*b));}
export fn fm_index_locate(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<5 or length>max_input)return -1;const input=input_opt.?;const n64=input[0];if(n64<1 or n64>32 or length<@as(usize,@intCast(n64))+4)return -1;const n:usize=@intCast(n64);const m_at=n+1;const m64=input[m_at];if(m64<1 or m64>8 or length!=m_at+2+@as(usize,@intCast(m64)))return -1;const m:usize=@intCast(m64);const stride64=input[length-1];if(stride64<1 or stride64>n64)return -1;const stride:usize=@intCast(stride64);const total=n+1;
 var s:[33]i64=[_]i64{0}**33;var pat:[8]i64=undefined;for(0..n)|i|{const x=input[i+1];if(x<1 or x>4)return -1;s[i]=x;}for(0..m)|i|{const x=input[m_at+1+i];if(x<1 or x>4)return -1;pat[i]=x;}s[n]=0;
 var sa:[33]usize=undefined;for(0..total)|i|sa[i]=i;for(1..total)|i|{const key=sa[i];var j=i;while(j>0 and lessSuffix(&s,total,key,sa[j-1])){sa[j]=sa[j-1];j-=1;}sa[j]=key;}
 var bwt:[33]usize=undefined;var freq:[5]usize=[_]usize{0}**alphabet;for(0..total)|i|{bwt[i]=@intCast(s[(sa[i]+total-1)%total]);freq[bwt[i]]+=1;}var C:[5]usize=[_]usize{0}**alphabet;var acc:usize=0;for(0..alphabet)|c|{C[c]=acc;acc+=freq[c];}
 var left:usize=0;var right=total;var j=m;while(j>0){j-=1;const sym:usize=@intCast(pat[j]);var rl:usize=0;var rr:usize=0;for(0..left)|x|{if(bwt[x]==sym)rl+=1;}for(0..right)|x|{if(bwt[x]==sym)rr+=1;}left=C[sym]+rl;right=C[sym]+rr;if(left==right)break;}
 var lf:[33]usize=undefined;var sampled:[33]bool=[_]bool{false}**33;var samples:[33]usize=undefined;for(0..total)|row|{const sym=bwt[row];var rank:usize=0;for(0..row)|x|{if(bwt[x]==sym)rank+=1;}lf[row]=C[sym]+rank;sampled[row]=sa[row]%stride==0;samples[row]=sa[row];}
 var loc:[32]i64=[_]i64{0}**32;var count:usize=0;for(left..right)|origin|{var row=origin;var steps:usize=0;while(!sampled[row] and steps<total){row=lf[row];steps+=1;}if(!sampled[row])return -1;const pos=(samples[row]+steps)%total;if(pos>=n)return -1;loc[count]=@intCast(pos);count+=1;}
 const bytes=8*(count+1);if(output_opt==null or capacity<bytes)return -2;const out=output_opt.?;store(out,0,@intCast(count));for(0..count)|i|store(out,8*(i+1),loc[i]);return @intCast(bytes);
}
