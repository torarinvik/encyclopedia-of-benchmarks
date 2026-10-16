module nearest_neighbour_algorithm;
fn long nearest_neighbour_algorithm(long*v,usz n,char*out,usz cap) @export("nearest_neighbour_algorithm") {
 if(v==null||n<2||n>257||v[0]<1||v[0]>16)return -1;usz m=(usz)v[0];if(n!=1+m*m)return -1;for(usz i=1;i<n;i++)if(v[i]<0||v[i]>1000000)return -1;
 bool[16] seen;usz[16] path;usz current=0;for(usz step=0;step<m;step++){path[step]=current;seen[current]=true;if(step+1==m)break;usz best=m;long dist=0;for(usz j=0;j<m;j++)if(!seen[j]){long d=v[1+current*m+j];if(best==m||d<dist){best=j;dist=d;}}current=best;}
 char[64] b;usz used=0;for(usz i=0;i<m;i++){if(i>0)b[used++]=',';usz x=path[i];if(x>=10)b[used++]=(char)('0'+x/10);b[used++]=(char)('0'+x%10);}if(used>cap)return -2;for(usz i=0;i<used;i++)out[i]=b[i];return (long)used;
}
