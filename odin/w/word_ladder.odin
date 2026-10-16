package word_ladder
import "core:c"
@(export)
word_ladder :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
 if input==nil || length<4 do return -1
 width_v,begin,ending,count_v:=input[0],input[1],input[2],input[3]
 if width_v<1||width_v>5||count_v<0||count_v>32 do return -1
 width,count:=int(width_v),int(count_v)
 if length!=c.size_t(4+count) do return -1
 limit:i64=1;for _ in 0..<width{limit*=26}
 if begin<0||begin>=limit||ending<0||ending>=limit do return -1
 dict:[32]i64;has_end:=false
 for i:=0;i<count;i+=1{code:=input[4+i];if code<0||code>=limit do return -1;dict[i]=code;if code==ending{has_end=true}}
 if output==nil||capacity<8 do return -2
 answer:i64=0
 if has_end {
  queue:[33]i64;dist:[33]i64;head,tail:=0,1;queue[0]=begin;dist[0]=1
  for head<tail&&answer==0 {
   word,depth:=queue[head],dist[head];head+=1;place:i64=1
   for _ in 0..<width {
    if answer!=0 do break
    digit:=(word/place)%26
    for letter:=i64(0);letter<26;letter+=1 {
     if letter==digit do continue
     next:=word+(letter-digit)*place
     if next==ending{answer=depth+1;break}
     in_dict:=false;for j:=0;j<count;j+=1{if dict[j]==next{in_dict=true;break}}
     seen:=false;for j:=1;j<tail;j+=1{if queue[j]==next{seen=true;break}}
     if in_dict&&!seen&&tail<33{queue[tail]=next;dist[tail]=depth+1;tail+=1}
    };place*=26
   }
  }
 }
 bits:=transmute(u64)answer;for b:=0;b<8;b+=1{output[b]=u8(bits>>u64(8*b))};return 8
}
