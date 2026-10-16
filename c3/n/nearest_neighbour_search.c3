module nearest_neighbour_search;
fn usz node_base(usz d,usz i){return 2+d+i*(d+2);}
bool valid_tree(long*v,usz d,usz n,long i,bool*seen,usz*reached){if(i<0)return true;usz j=(usz)i;if(j>=n||seen[j])return false;seen[j]=true;reached[0]++;usz b=node_base(d,j);long l=v[b+d],r=v[b+d+1];if(l>=0&&l==r)return false;return valid_tree(v,d,n,l,seen,reached)&&valid_tree(v,d,n,r,seen,reached);}
void search_tree(long*v,usz d,long i,usz depth,long*q,long*best,long*bestd,long*visited){if(i<0)return;visited[0]++;usz b=node_base(d,(usz)i);long dist=0;for(usz k=0;k<d;k++){long delta=q[k]-v[b+k];dist+=delta*delta;}if(dist<bestd[0]){bestd[0]=dist;for(usz k=0;k<d;k++)best[k]=v[b+k];}usz axis=depth%d;long l=v[b+d],r=v[b+d+1],near=l,far=r;if(q[axis]>v[b+axis]){near=r;far=l;}search_tree(v,d,near,depth+1,q,best,bestd,visited);long split=q[axis]-v[b+axis];if(split*split<bestd[0])search_tree(v,d,far,depth+1,q,best,bestd,visited);}
void put_i64(char*out,usz off,long x){ulong bits=@bitcast(ulong,x);for(usz k=0;k<8;k++){out[off+k]=(char)(bits&255);bits>>=8;}}
fn long nearest_neighbour_search(long*v,usz n,char*out,usz cap)@export("nearest_neighbour_search"){
 if(v==null||n<5)return -1;long d0=v[0],n0=v[1];if((d0!=2&&d0!=3)||n0<1||n0>15)return -1;usz d=(usz)d0,count=(usz)n0;if(n!=2+d+count*(d+2))return -1;long[3] q,best;
 for(usz k=0;k<d;k++){q[k]=v[2+k];if(q[k]< -1000||q[k]>1000)return -1;}
 for(usz i=0;i<count;i++){usz b=node_base(d,i);for(usz k=0;k<d;k++)if(v[b+k]< -1000||v[b+k]>1000)return -1;long l=v[b+d],r=v[b+d+1];if(l < -1||l>=n0||r < -1||r>=n0||(l>=0&&l==r))return -1;}
 bool[15] seen=zeroed;usz reached=0;if(!valid_tree(v,d,count,0,&seen[0],&reached)||reached!=count)return -1;long bestd=9223372036854775807,visited=0;search_tree(v,d,0,0,&q[0],&best[0],&bestd,&visited);if(out==null||cap<48)return -2;long[6] result={d0,best[0],best[1],0,bestd,visited};if(d==3)result[3]=best[2];for(usz k=0;k<6;k++)put_i64(out,k*8,result[k]);return 48;
}
