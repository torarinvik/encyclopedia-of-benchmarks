module deterministic_line_search;
fn void put_i64_le(char*out,usz p,long x){ulong u=(ulong)x;for(usz b=0;b<8;b++){out[p+b]=(char)(u&255);u>>=8;}}
fn long deterministic_line_search(long*in,usz len,char*out,usz cap) @export("deterministic_line_search"){
 if(in==null||len!=1)return -1;long target=in[0];if(target==0||target< -50000||target>50000)return -1;
 long distance=target<0?-target:target,traveled=0,leg=0,depth=1;
 while(true){bool negative=(leg%2)==0;if((target<0)==negative&&distance<=depth){traveled+=distance;break;}traveled+=2*depth;depth*=2;leg++;}
 if(cap<16||out==null)return -2;put_i64_le(out,0,traveled);put_i64_le(out,8,leg);return 16;
}
