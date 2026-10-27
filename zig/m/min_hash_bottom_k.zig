const MAX_INPUT:usize=35;
fn put64(o:[*]u8,p:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|j|o[p+j]=@truncate(b>>@intCast(8*j));}
export fn min_hash_bottom_k(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<4 or length>MAX_INPUT)return -1;const in=input_opt.?;const nr=in[0];const kr=in[1];if(nr<1 or nr>16 or kr<1 or kr>8 or length!=2+2*@as(usize,@intCast(nr)))return -1;const n:usize=@intCast(nr);const k:usize=@intCast(kr);var ids:[16]usize=@splat(0);var ranks:[16]i64=@splat(0);var count:usize=0;
 for(0..n)|i|{const id=in[2+2*i];const rank=in[3+2*i];if(id<0 or id>=16 or rank<0 or rank>1000)return -1;for(0..i)|j|{if(id==in[2+2*j])return -1;}var pos:usize=0;while(pos<count and (ranks[pos]<rank or (ranks[pos]==rank and ids[pos]<@as(usize,@intCast(id))))){pos+=1;}if(pos<k){var next:usize=if(count<k)count else k-1;while(next>pos){ids[next]=ids[next-1];ranks[next]=ranks[next-1];next-=1;}ids[pos]=@intCast(id);ranks[pos]=rank;if(count<k)count+=1;}}
 const bytes=8*(1+2*count);if(output_opt==null or capacity<bytes)return -2;const out=output_opt.?;put64(out,0,@intCast(count));for(0..count)|i|{put64(out,8+16*i,@intCast(ids[i]));put64(out,16+16*i,ranks[i]);}return @intCast(bytes);
}
