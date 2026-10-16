module local_binary_pattern;
fn long local_binary_pattern(long*v,usz n) @export("local_binary_pattern"){if(v==null||n!=9)return -1;for(usz i=0;i<9;i++)if(v[i]<0||v[i]>255)return -1;usz ix[8]={2,5,1,8,7,6,3,0};long out=0;for(usz i=0;i<8;i++)if(v[ix[i]]>=v[4])out|=1<<i;return out;}
