package min_hash_bottom_k
import "core:c"
MAX_INPUT :: 35
put64 :: proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
min_hash_bottom_k :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||length>MAX_INPUT do return -1
 nr:=input[0];kr:=input[1];if nr<1||nr>16||kr<1||kr>8||length!=c.size_t(2+2*nr) do return -1
 n:=int(nr);k:=int(kr);ids:[16]int; ranks:[16]i64;count:=0
 for i:=0;i<n;i+=1{ id:=input[2+2*i];rank:=input[3+2*i];if id<0||id>=16||rank<0||rank>1000 do return -1
  for j:=0;j<i;j+=1{if id==input[2+2*j] do return -1}
  pos:=0;for pos<count&&(ranks[pos]<rank||(ranks[pos]==rank&&ids[pos]<int(id))){pos+=1}
  if pos<k{next:=count;if next>=k{next=k-1};for next>pos{ids[next]=ids[next-1];ranks[next]=ranks[next-1];next-=1};ids[pos]=int(id);ranks[pos]=rank;if count<k{count+=1}}
 }
 bytes:=8*(1+2*count);if output==nil||capacity<c.size_t(bytes) do return -2;put64(output,0,i64(count));for i:=0;i<count;i+=1{put64(output,8+16*i,i64(ids[i]));put64(output,16+16*i,ranks[i])};return i64(bytes)
}
