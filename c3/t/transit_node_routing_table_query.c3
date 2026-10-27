module transit_node_routing_table_query;

fn void put_i64(uint8* out,long word,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[word*8+(long)b]=(uint8)(bits>>(8*b));}

fn long transit_node_routing_table_query(long* input,usz length,uint8* output,usz capacity) @export("transit_node_routing_table_query"){
    if(input==null||length<11||length>86)return -1;long q0=input[0],source=input[1],target=input[2];if(q0<1||q0>8||source<0||source>=32||target<0||target>=32||input[3]!=1)return -1;long q=q0;usz at=4;long nf0=input[at];at++;if(nf0<1||nf0>4||nf0>q0||at+2*(usz)nf0>length)return -1;long nf=nf0;long[8] f;long[8] ds;
    for(long i=0;i<nf;i++){long u=input[at],d=input[at+1];at+=2;if(u<0||u>=q0||d<0||d>1000000)return -1;for(long j=0;j<i;j++)if(f[j]==u)return -1;f[i]=u;ds[i]=d;}
    if(at>=length)return -1;long nb0=input[at];at++;if(nb0<1||nb0>4||nb0>q0||at+2*(usz)nb0>length)return -1;long nb=nb0;long[8] b;long[8] dt;
    for(long i=0;i<nb;i++){long v=input[at],d=input[at+1];at+=2;if(v<0||v>=q0||d<0||d>1000000)return -1;for(long j=0;j<i;j++)if(b[j]==v)return -1;b[i]=v;dt[i]=d;}
    if(at+(usz)(q*q)!=length)return -1;long[64] table;for(long i=0;i<q;i++)for(long j=0;j<q;j++){long d=input[at];at++;if(d<0||d>1000000)return -1;table[i*8+j]=d;}
    for(long i=0;i<q;i++)if(table[i*8+i]!=0)return -1;long best=9223372036854775807,bestu=0,bestv=0;
    for(long i=0;i<nf;i++)for(long j=0;j<nb;j++){long d=ds[i]+table[f[i]*8+b[j]]+dt[j];if(d<best||(d==best&&(f[i]<bestu||(f[i]==bestu&&b[j]<bestv)))){best=d;bestu=f[i];bestv=b[j];}}
    if(output==null||capacity<24)return -2;put_i64(output,0,best);put_i64(output,1,bestu);put_i64(output,2,bestv);return 24;
}
