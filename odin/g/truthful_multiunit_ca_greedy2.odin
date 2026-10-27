package truthful_multiunit_ca_greedy2

import "core:c"
import "core:math"

MAX_ITEMS :: 6
MAX_BIDDERS :: 12
MAX_INPUT :: 32
MAX_OUTPUT :: 104

put_i64 :: proc(out: [^]u8, offset: int, value: i64) { bits:=u64(value); for b:=0;b<8;b+=1 { out[offset+b]=u8((bits>>(8*b))&255) } }

@(export)
truthful_multiunit_ca_greedy2 :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
 if values==nil || int(length)<5 || int(length)>MAX_INPUT do return -1
 if values[0]<2 || values[0]>i64(MAX_ITEMS) || values[1]<1 || values[1]>i64(MAX_BIDDERS) do return -1
 items,bidders:=int(values[0]),int(values[1]); if int(length)!=2+items+2*bidders do return -1
 caps:[MAX_ITEMS]int; prices:[MAX_ITEMS]f64; minimum:=9
 for e:=0;e<items;e+=1 { if values[2+e]<1 || values[2+e]>8 do return -1; caps[e]=int(values[2+e]); if caps[e]<minimum do minimum=caps[e]; prices[e]=1.0/f64(caps[e]) }
 bids:[MAX_BIDDERS]int; masks:[MAX_BIDDERS]int
 for i:=0;i<bidders;i+=1 { value,mask:=values[2+items+2*i],values[3+items+2*i]; if value<1||value>100||mask<1||mask>=(1<<items) do return -1; bids[i]=int(value); masks[i]=int(mask) }
 threshold:=math.pow_f64(2.718281828459045,f64(minimum))*f64(items); chosen:[MAX_BIDDERS]bool = {}; order:[MAX_BIDDERS]int; count:=0
 for count<bidders {
  best:=-1; best_score:=-1.0
  for i:=0;i<bidders;i+=1 { if !chosen[i] { denominator:=0.0; for e:=0;e<items;e+=1 { if (masks[i]&(1<<e))!=0 do denominator+=prices[e] }; score:=f64(bids[i])/denominator; if best<0||score>best_score {best=i;best_score=score} } }
  if best<0 do break; chosen[best]=true; order[count]=best; count+=1
  for e:=0;e<items;e+=1 { if (masks[best]&(1<<e))!=0 do prices[e]*=math.pow_f64(threshold,1.0/f64(caps[e])) }
  dual:=0.0; for e:=0;e<items;e+=1 {dual+=f64(caps[e])*prices[e]}; if dual>=threshold do break
 }
 bytes:=8*(1+count); if output==nil||int(capacity)<bytes do return -2
 staged:[MAX_OUTPUT]u8; put_i64(&staged[0],0,i64(count)); for i:=0;i<count;i+=1 {put_i64(&staged[0],8*(i+1),i64(order[i]))}; for i:=0;i<bytes;i+=1 {output[i]=staged[i]}; return i64(bytes)
}
