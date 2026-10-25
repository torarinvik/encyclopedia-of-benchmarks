module mediabench_mpeg2_motion_vector_component;
fn void put(u8*o,long x){ulong u=(ulong)x;for(usz b=0;b<8;b++)o[b]=(u8)((u>>(8*b))&255);}
fn long mediabench_mpeg2_motion_vector_component(long*v,usz n,u8*out,usz cap) @export("mediabench_mpeg2_motion_vector_component"){
 if(v==null||n!=4)return -1;long pred=v[0];long rs=v[1];long code=v[2];long res=v[3];if(rs<0||rs>6||code < -16||code>16)return -1;long lim=16<<rs;if(pred < -lim||pred>=lim)return -1;if((code==0||rs==0)?res!=0:(res<0||res>=(1<<rs)))return -1;long vec=pred;if(code>0){vec+=((code-1)<<rs)+res+1;if(vec>=lim)vec-=2*lim;}else if(code<0){vec-=((-code-1)<<rs)+res+1;if(vec < -lim)vec+=2*lim;}if(out==null||cap<8)return -2;put(out,vec);return 8;
}
