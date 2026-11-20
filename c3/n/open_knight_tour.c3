module open_knight_tour;
const int[8] DR={1,-1,1,-1,2,2,-2,-2};const int[8] DC={2,2,-2,-2,1,-1,1,-1};
fn bool search(int *b,int n,int r,int c,int step){if(step==n*n)return true;for(int k=0;k<8;k++){int nr=r+DR[k],nc=c+DC[k];if(nr>=0&&nr<n&&nc>=0&&nc<n&&b[nr*n+nc]==0){b[nr*n+nc]=step+1;if(search(b,n,nr,nc,step+1))return true;b[nr*n+nc]=0;}}return false;}
fn void put(char*out,usz off,int x){uint bits=(uint)x;for(usz k=0;k<4;k++){out[off+k]=(char)(bits&255);bits>>=8;}}
fn long open_knight_tour(long*v,usz n,char*out,usz cap)@export("open_knight_tour"){if(v==null||n!=1||(v[0]!=1&&v[0]!=5))return -1;int d=(int)v[0];int[25] b={};usz bytes=(usz)(d*d*4);if(out==null||cap<bytes)return -2;bool found=false;for(int r=0;r<d;r++){for(int c=0;c<d;c++){b[r*d+c]=1;if(search(&b[0],d,r,c,1)){found=true;break;}b[r*d+c]=0;}if(found)break;}for(int i=0;i<d*d;i++)put(out,(usz)(i*4),b[i]);return (long)bytes;}
