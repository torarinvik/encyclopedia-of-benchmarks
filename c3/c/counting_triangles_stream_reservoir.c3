module counting_triangles_stream_reservoir;

fn void put_i64(uint8* out,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[b]=(uint8)(bits>>(8*b));}
fn long counting_triangles_stream_reservoir(long* input,usz length,uint8* output,usz capacity) @export("counting_triangles_stream_reservoir"){
    if(input==null||length<6||length>114)return -1;
    long n0=input[0],m0=input[1];if(n0<2||n0>8||m0<1||m0>28||length!=2+4*(usz)m0)return -1;
    usz n=(usz)n0,m=(usz)m0;bool[8][8] seen;long[28][2] edges;
    for(usz i=0;i<m;i++){long u=input[2+2*i],v=input[3+2*i];if(u<0||v<=u||v>=n0||seen[(usz)u][(usz)v])return -1;seen[(usz)u][(usz)v]=true;seen[(usz)v][(usz)u]=true;edges[i][0]=u;edges[i][1]=v;}
    usz base=2+2*m;for(usz t=1;t<=m;t++)for(usz s=0;s<2;s++){long r=input[base+2*(t-1)+s];if(r<0||r>=(long)t)return -1;}
    long[2][2] slots;slots[0][0]=-1;slots[0][1]=-1;slots[1][0]=-1;slots[1][1]=-1;long[112] staged;usz at=0;
    for(usz t=1;t<=m;t++){for(usz s=0;s<2;s++)if(input[base+2*(t-1)+s]==0){slots[s][0]=edges[t-1][0];slots[s][1]=edges[t-1][1];}for(usz s=0;s<2;s++){staged[at]=slots[s][0];at++;staged[at]=slots[s][1];at++;}}
    usz bytes=16*m;if(output==null||capacity<bytes)return -2;for(usz i=0;i<at;i++)put_i64(output+8*i,staged[i]);return (long)bytes;
}
