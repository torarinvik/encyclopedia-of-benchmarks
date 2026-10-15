module range_minimum_query;
const usz MAX_N = 64, MAX_Q = 64;
fn void put_i64(long value, char* out, usz offset) { ulong bits = (ulong)value; for (usz b=0;b<8;b++){out[offset+b]=(char)(bits&255);bits>>=8;} }
fn long range_minimum_query(long* input, usz length, char* output, usz capacity) @export("range_minimum_query") {
    if(input==null||length<4)return -1;long n64=input[0];if(n64<1||n64>MAX_N)return -1;usz n=(usz)n64;usz qp=1+n;if(length<=qp)return -1;long q64=input[qp];if(q64<1||q64>MAX_Q)return -1;usz q=(usz)q64;if(length!=qp+1+2*q)return -1;
    long[MAX_N] values;for(usz i=0;i<n;i++){values[i]=input[1+i];if(values[i]<-1000||values[i]>1000)return -1;}if(capacity<q*8||output==null)return -2;
    usz[7][MAX_N] table;for(usz i=0;i<n;i++)table[0][i]=i;
    usz k=1;while((1<<k)<=n){usz width=1<<k,half=width>>1;usz i=0;while(i+width<=n){usz a=table[k-1][i],b=table[k-1][i+half];table[k][i]=values[a]<values[b]?a:b;i++;}k++;}
    long invalid=-9223372036854775807-1;
    for(usz j=0;j<q;j++){long l=input[qp+1+2*j],r=input[qp+2+2*j],answer=invalid;if(l>=0&&r>l&&r<=n){usz left=(usz)l,right=(usz)r,size=right-left,level=0;while((1<<(level+1))<=size)level++;usz width=1<<level,a=table[level][left],b=table[level][right-width];answer=values[a]<values[b]?values[a]:values[b];}put_i64(answer,output,j*8);}
    return (long)(q*8);
}
