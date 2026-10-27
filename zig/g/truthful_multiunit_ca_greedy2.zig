const std=@import("std");
const MAX_ITEMS:usize=6;const MAX_BIDDERS:usize=12;const MAX_INPUT:usize=32;const MAX_OUTPUT:usize=104;
fn putI64(out:[*c]u8,at:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|out[at+i]=@truncate(b>>(8*@as(u6,@intCast(i))));}
export fn truthful_multiunit_ca_greedy2(values:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(values==null or length<5 or length>MAX_INPUT)return -1;
 if(values[0]<2 or values[0]>MAX_ITEMS or values[1]<1 or values[1]>MAX_BIDDERS)return -1;
 const items:usize=@intCast(values[0]);const bidders:usize=@intCast(values[1]);if(length!=2+items+2*bidders)return -1;
 var caps:[MAX_ITEMS]usize=@splat(0);var prices:[MAX_ITEMS]f64=@splat(0.0);var minimum:usize=9;
 for(0..items)|e|{if(values[2+e]<1 or values[2+e]>8)return -1;caps[e]=@intCast(values[2+e]);minimum=@min(minimum,caps[e]);prices[e]=1.0/@as(f64,@floatFromInt(caps[e]));}
 var bids:[MAX_BIDDERS]i64=@splat(0);var masks:[MAX_BIDDERS]usize=@splat(0);
 for(0..bidders)|i|{const value=values[2+items+2*i];const mask=values[3+items+2*i];if(value<1 or value>100 or mask<1 or mask>=(@as(i64,1)<<@as(u6,@intCast(items))))return -1;bids[i]=value;masks[i]=@intCast(mask);}
 const threshold=std.math.pow(f64,2.718281828459045,@as(f64,@floatFromInt(minimum)))*@as(f64,@floatFromInt(items));var chosen:[MAX_BIDDERS]bool=@splat(false);var order:[MAX_BIDDERS]usize=@splat(0);var count:usize=0;
 while(count<bidders){var best:?usize=null;var best_score:f64=-1.0;for(0..bidders)|i|{if(!chosen[i]){var den:f64=0.0;for(0..items)|e|{if((masks[i]&(1<<@as(u6,@intCast(e))))!=0)den+=prices[e];}const score=@as(f64,@floatFromInt(bids[i]))/den;if(best==null or score>best_score){best=i;best_score=score;}}}if(best==null)break;const i=best.?;chosen[i]=true;order[count]=i;count+=1;
  for(0..items)|e|{if((masks[i]&(1<<@as(u6,@intCast(e))))!=0)prices[e]*=std.math.pow(f64,threshold,1.0/@as(f64,@floatFromInt(caps[e])));}
  var dual:f64=0.0;for(0..items)|e|dual+=@as(f64,@floatFromInt(caps[e]))*prices[e];if(dual>=threshold)break;
 }
 const bytes=8*(1+count);if(output==null or capacity<bytes)return -2;var staged:[MAX_OUTPUT]u8=@splat(0);putI64(&staged,0,@intCast(count));for(0..count)|i|putI64(&staged,8*(i+1),@intCast(order[i]));for(0..bytes)|i|output[i]=staged[i];return @intCast(bytes);
}
