// Clean-room Lexicographic Depth-First Search with 4-vertex certificates.
const N:usize=8;const FIELDS:usize=234;
fn put(out:[*]u8,at:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|out[at+i]=@truncate(b>>@intCast(8*i));}
export fn ldfs_ordering_certificate(v:[*c]const i64,n:usize,out_opt:?[*]u8,cap:usize)i64{
 if(v==null||n<3||n>10||v[0]<1||v[0]>8)return -1;const count:usize=@intCast(v[0]);if(n!=count+2||v[1]<0||v[1]>=@as(i64,@intCast(count)))return -1;const all=(@as(u64,1)<<@intCast(count))-1;var adj:[N]u64=@splat(0);
 for(0..count)|i|{if(v[2+i]<0||@as(u64,@intCast(v[2+i]))>all||((@as(u64,@intCast(v[2+i]))>>@intCast(i))&1)!=0)return -1;adj[i]=@intCast(v[2+i]);}for(0..count)|i|{for(0..count)|j|{if(((adj[i]>>@intCast(j))&1)!=((adj[j]>>@intCast(i))&1))return -1;}}
 var reach=@as(u64,1)<<@intCast(v[1]);for(0..count)|_|{const old=reach;for(0..count)|i|{if(((reach>>@intCast(i))&1)!=0)reach|=adj[i];}if(old==reach)break;}if(reach!=all)return -1;
 var order:[N]usize=@splat(0);order[0]=@intCast(v[1]);var used:usize=1;var visited=@as(u64,1)<<@intCast(v[1]);while(used<count){var chosen=count;for(0..count)|x|{if(((visited>>@intCast(x))&1)==0){var wins=chosen==count;if(!wins){var k=used;while(k>0){k-=1;const u=order[k];const xb=(adj[x]>>@intCast(u))&1;const yb=(adj[chosen]>>@intCast(u))&1;if(xb!=yb){wins=xb>yb;break;}if(k==0)wins=x<chosen;}}if(wins)chosen=x;}}order[used]=chosen;used+=1;visited|=@as(u64,1)<<@intCast(chosen);}
 var fields:[FIELDS]i64=@splat(0);fields[0]=@intCast(count);for(0..count)|i|fields[1+i]=@intCast(order[i]);var certs:usize=0;var at=count+2;
 for(0..count)|i|{for(i+1..count)|j|{for(j+1..count)|k|{const a=order[i];const b=order[j];const c=order[k];if(((adj[a]>>@intCast(c))&1)!=0&&((adj[a]>>@intCast(b))&1)==0){var witness:i64=-1;for(i+1..j)|t|{const d=order[t];if(((adj[d]>>@intCast(b))&1)!=0&&((adj[d]>>@intCast(c))&1)==0){witness=@intCast(d);break;}}fields[at]=@intCast(a);fields[at+1]=@intCast(b);fields[at+2]=@intCast(c);fields[at+3]=witness;at+=4;certs+=1;}}}}
 fields[count+1]=@intCast(certs);const bytes=8*at;if(out_opt==null||cap<bytes)return -2;const out=out_opt.?;var staged:[FIELDS*8]u8=@splat(0);for(0..at)|i|put(&staged,8*i,fields[i]);@memcpy(out[0..bytes],staged[0..bytes]);return @intCast(bytes)
}
