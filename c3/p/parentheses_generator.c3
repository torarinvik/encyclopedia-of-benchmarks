module parentheses_generator;
const long[7] COUNTS={1,1,2,5,14,42,132};
fn void gen(long n,long open,long close,char* path,char* out,long* index){if(open+close==2*n){for(long i=0;i<2*n;i++)out[2+(*index)*(2*n)+i]=path[i];*index+=1;return;}if(open<n){path[open+close]='(';gen(n,open+1,close,path,out,index);}if(close<open){path[open+close]=')';gen(n,open,close+1,path,out,index);}}
fn long parentheses_generator(long* v,usz n,char* out,usz cap) @export("parentheses_generator"){if(v==null||n!=1||v[0]<0||v[0]>6)return -1;long k=v[0],need=2+COUNTS[k]*2*k;if((usz)need>cap||out==null)return -2;out[0]=(char)COUNTS[k];out[1]=(char)(COUNTS[k]>>8);char[12] path;long index=0;gen(k,0,0,path,out,&index);return need;}
