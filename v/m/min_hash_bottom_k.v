module min_hash_bottom_k
fn put64(output &u8,pos int,value i64){bits:=u64(value);unsafe{for b in 0..8{output[pos+b]=u8((bits>>(8*b))&255)}}}
@[export: 'min_hash_bottom_k']
pub fn min_hash_bottom_k(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<4||length>35{return -1}
  nr:=input[0];kr:=input[1];if nr<1||nr>16||kr<1||kr>8||length!=usize(2+2*nr){return -1}
  n:=int(nr);k:=int(kr);mut ids:=[16]int{};mut ranks:=[16]i64{};mut count:=0
  for i in 0..n{ id:=input[2+2*i];rank:=input[3+2*i];if id<0||id>=16||rank<0||rank>1000{return -1}
   for j in 0..i{if id==input[2+2*j]{return -1}}
   mut pos:=0;for pos<count&&(ranks[pos]<rank||(ranks[pos]==rank&&ids[pos]<int(id))){pos++}
   if pos<k{mut next:=count;if next>=k{next=k-1};for next>pos{ids[next]=ids[next-1];ranks[next]=ranks[next-1];next--};ids[pos]=int(id);ranks[pos]=rank;if count<k{count++}}
  }
  bytes:=8*(1+2*count);if output==nil||capacity<usize(bytes){return -2}
  put64(output,0,i64(count));for i in 0..count{put64(output,8+16*i,i64(ids[i]));put64(output,16+16*i,ranks[i])};return i64(bytes)
 }
}
