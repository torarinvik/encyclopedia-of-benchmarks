module mediabench_mpeg2_motion_vector_component
fn put(out &u8,x i64){u:=u64(x);for b in 0..8{unsafe{out[b]=u8((u>>u64(8*b))&255)}}}
@[export:'mediabench_mpeg2_motion_vector_component']
pub fn mediabench_mpeg2_motion_vector_component(raw &i64,n usize,out &u8,cap usize)i64{
 unsafe {
  if raw==nil||n!=4{return -1};pred:=raw[0];rs:=raw[1];code:=raw[2];res:=raw[3];if rs<0||rs>6||code < -16||code>16{return -1};lim:=i64(16)<<u64(rs);if pred < -lim||pred>=lim{return -1};if code==0||rs==0{if res!=0{return -1}}else if res<0||res >= (i64(1)<<u64(rs)){return -1};mut vec:=pred;if code>0{vec+=((code-1)<<u64(rs))+res+1;if vec>=lim{vec-=2*lim}}else if code<0{vec-=((-code-1)<<u64(rs))+res+1;if vec < -lim{vec+=2*lim}};if out==nil||cap<8{return -2};put(out,vec);return 8
 }
}
