#include <stddef.h>
#include <stdint.h>
int64_t langtons_ant(const int64_t*v,size_t n){if(!v||n!=1||v[0]<0||v[0]>6)return -1;int b[25];for(int i=0;i<25;i++)b[i]=1;int x=2,y=2,d=3;int dx[4]={-1,0,1,0},dy[4]={0,1,0,-1};for(int s=0;s<v[0];s++){d=b[x*5+y]?(d+1)%4:(d+3)%4;int ox=x,oy=y;x+=dx[d];y+=dy[d];if(x<0||x>=5||y<0||y>=5)return -1;b[ox*5+oy]^=1;}int64_t mask=0;for(int i=0;i<25;i++)if(!b[i])mask|=(int64_t)1<<i;return mask|((int64_t)(x*5+y)<<25)|((int64_t)d<<30);}
