module one_hot_encode;
fn long one_hot_encode(long*v,usz n,char*out,usz cap) @export("one_hot_encode") {
 if(v==null||n<2||n>33||v[0]<1||v[0]>32||n!=(usz)v[0]+1)return -1;usz rows=(usz)v[0];bool[26] present;for(usz i=0;i<rows;i++){if(v[i+1]<0||v[i+1]>25)return -1;present[(usz)v[i+1]]=true;}
 usz[26] map;usz cols=0;for(usz i=0;i<26;i++)if(present[i]){map[i]=cols;cols++;}usz need=rows*cols;if(need>cap||(need>0&&out==null))return -2;for(usz r=0;r<rows;r++)for(usz c=0;c<cols;c++)out[r*cols+c]=(char)(map[(usz)v[r+1]]==c?1:0);return (long)need;
}
