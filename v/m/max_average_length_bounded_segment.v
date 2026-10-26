@[export: 'max_average_length_bounded_segment']
pub fn max_average_length_bounded_segment(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<4||length>35{return -1}n64:=input[0];lower64:=input[1];upper64:=input[2]
  if n64<1||n64>32||lower64<1||upper64<lower64||upper64>n64||length!=usize(3+n64){return -1};n:=int(n64);lower:=int(lower64);upper:=int(upper64)
  for i in 0..n{if input[3+i]< -10000||input[3+i]>10000{return -1}}if output==nil||capacity<32{return -2}
  mut best_sum:=i64(0);mut best_len:=1;mut best_start:=0;mut best_end:=0;mut have:=false
  for start in 0..n{mut sum:=i64(0);limit:=if start+upper<n{start+upper}else{n};for end in start+1..limit+1{sum+=input[3+end-1];size:=end-start;if size<lower{continue};left:=sum*i64(best_len);right:=best_sum*i64(size)
   tie:=size<best_len||(size==best_len&&(start<best_start||(start==best_start&&end<best_end)))
   if !have||left>right||(left==right&&tie){best_sum,best_len,best_start,best_end,have=sum,size,start,end,true}
  }}
  values:=[4]i64{best_sum,i64(best_len),i64(best_start),i64(best_end)}
  for i,value in values{bits:=u64(value);for b in 0..8{output[8*i+b]=u8((bits>>(8*b))&255)}}return 32
 }
}
