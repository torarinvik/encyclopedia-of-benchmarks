module main
import math

const max_items = 6
const max_bidders = 12
const max_input = 32
const max_output = 104

fn put_i64(mut output &u8, offset int, value i64) { bits:=u64(value); unsafe { for b in 0..8 { output[offset+b]=u8((bits>>(8*b))&255) } } }

@[export: 'truthful_multiunit_ca_greedy2']
pub fn truthful_multiunit_ca_greedy2(values &i64, length usize, mut output &u8, capacity usize) i64 {
 unsafe {
  if values==nil||length<5||length>max_input{return -1}
  if values[0]<2||values[0]>max_items||values[1]<1||values[1]>max_bidders{return -1}
  items,bidders:=int(values[0]),int(values[1]);if length!=usize(2+items+2*bidders){return -1}
  mut caps:=[max_items]int{};mut prices:=[max_items]f64{};mut minimum:=9
  for e in 0..items { if values[2+e]<1||values[2+e]>8{return -1};caps[e]=int(values[2+e]);if caps[e]<minimum{minimum=caps[e]};prices[e]=1.0/f64(caps[e]) }
  mut bids:=[max_bidders]int{};mut masks:=[max_bidders]int{}
  for i in 0..bidders { value,mask:=values[2+items+2*i],values[3+items+2*i];if value<1||value>100||mask<1||mask>=i64(1<<items){return -1};bids[i]=int(value);masks[i]=int(mask) }
  threshold:=math.pow(2.718281828459045,f64(minimum))*f64(items);mut chosen:=[max_bidders]bool{};mut order:=[max_bidders]int{};mut count:=0
  for count<bidders { mut best:=-1;mut best_score:=-1.0
   for i in 0..bidders {if !chosen[i]{mut denominator:=0.0;for e in 0..items{if (masks[i]&(1<<e))!=0{denominator+=prices[e]}};score:=f64(bids[i])/denominator;if best<0||score>best_score{best=i;best_score=score}}}
   if best<0{break};chosen[best]=true;order[count]=best;count++
   for e in 0..items{if (masks[best]&(1<<e))!=0{prices[e]*=math.pow(threshold,1.0/f64(caps[e]))}}
   mut dual:=0.0;for e in 0..items{dual+=f64(caps[e])*prices[e]};if dual>=threshold{break}
  }
  bytes:=8*(1+count);if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};put_i64(mut staged[0],0,i64(count));for i in 0..count{put_i64(mut staged[0],8*(i+1),i64(order[i]))};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
 }
}
