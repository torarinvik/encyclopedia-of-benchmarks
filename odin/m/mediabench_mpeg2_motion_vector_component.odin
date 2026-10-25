package mediabench_mpeg2_motion_vector_component
import "core:c"
put :: proc "contextless"(o:[^]u8,x:i64){u:=u64(x);for b:=0;b<8;b+=1{o[b]=u8((u>>u64(8*b))&255)}}
@(export,link_name="mediabench_mpeg2_motion_vector_component")
mediabench_mpeg2_motion_vector_component :: proc "c"(v:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64{
 if v==nil||n!=4 do return -1;pred:=v[0];rs:=v[1];code:=v[2];res:=v[3];if rs<0||rs>6||code < -16||code>16 do return -1;lim:=i64(16)<<u64(rs);if pred < -lim||pred>=lim do return -1;if code==0||rs==0{if res!=0 do return -1}else if res<0||res >= (i64(1)<<u64(rs)) do return -1;vec:=pred;if code>0{vec+=((code-1)<<u64(rs))+res+1;if vec>=lim{vec-=2*lim}}else if code<0{vec-=((-code-1)<<u64(rs))+res+1;if vec < -lim{vec+=2*lim}};if out==nil||cap<8 do return -2;put(out,vec);return 8
}
