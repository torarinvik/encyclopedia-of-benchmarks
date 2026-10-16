module node_neighbors;
fn long node_neighbors(long*v,usz n,char*out,usz cap) @export("node_neighbors") {
 if(v==null||n<2||v[0]<0||v[0]>64||v[1]<0||v[1]>63||n!=2+2*(usz)v[0])return -1;bool[64] seen;char[192] b;usz used=0;
 for(usz i=0;i<(usz)v[0];i++){long a=v[2+2*i],c=v[3+2*i];if(a<0||a>63||c<0||c>63)return -1;long x=-1;if(a==v[1])x=c;else if(c==v[1])x=a;if(x>=0&&!seen[(usz)x]){seen[(usz)x]=true;if(used)b[used++]=',';usz value=(usz)x;char[3] digits;usz count=0;do{digits[count++]=(char)('0'+value%10);value/=10;}while(value);while(count)b[used++]=digits[--count];}}
 if(used>cap||(used>0&&out==null))return -2;for(usz i=0;i<used;i++)out[i]=b[i];return (long)used;
}
