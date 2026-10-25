fn put(out:[*]u8,x:i64)void{const u:u64=@bitCast(x);for(0..8)|b|out[b]=@truncate(u>>@intCast(8*b));}
export fn mediabench_mpeg2_motion_vector_component(raw:?[*]const i64,n:usize,raw_out:?[*]u8,cap:usize)i64{
 if(raw==null or n!=4)return -1;const v=raw.?[0..n];const pred=v[0];const rs=v[1];const code=v[2];const res=v[3];if(rs<0 or rs>6 or code < -16 or code>16)return -1;const lim:i64=16<<@intCast(rs);if(pred < -lim or pred>=lim)return -1;if(code==0 or rs==0){if(res!=0)return -1;}else if(res<0 or res >= (@as(i64,1)<<@intCast(rs)))return -1;var vec=pred;if(code>0){vec+=((code-1)<<@intCast(rs))+res+1;if(vec>=lim)vec-=2*lim;}else if(code<0){vec-=((-code-1)<<@intCast(rs))+res+1;if(vec < -lim)vec+=2*lim;}if(raw_out==null or cap<8)return -2;put(raw_out.?,vec);return 8;
}
