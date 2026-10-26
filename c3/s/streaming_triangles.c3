module streaming_triangles;

fn long power(int base,usz exp){long r=1;for(usz i=0;i<exp;i++)r*=base;return r;}
fn void put_i64(uint8* out,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[b]=(uint8)(bits>>(8*b));}
fn bool make_wedge(long* a,long* b,long* out){long c=-1;for(usz i=0;i<2;i++)for(usz j=0;j<2;j++)if(a[i]==b[j])c=a[i];if(c<0)return false;long x=a[0]==c?a[1]:a[0],y=b[0]==c?b[1]:b[0];if(x==y)return false;if(x>y){long z=x;x=y;y=z;}out[0]=x;out[1]=y;return true;}

fn long streaming_triangles(long* input,usz length,uint8* output,usz capacity) @export("streaming_triangles"){
    if(input==null||length<10||length>340)return -1;
    long n0=input[0],m0=input[1],se0=input[2],sw0=input[3];if(n0<2||n0>8||m0<1||m0>28||se0<2||se0>4||sw0<1||sw0>4)return -1;
    usz m=(usz)m0,se=(usz)se0,sw=(usz)sw0,stride=2+2*sw;if(length!=4+2*m+m*stride)return -1;
    long[28][2] edges;bool[8][8] seen;
    for(usz i=0;i<m;i++){long u=input[4+2*i],v=input[5+2*i];if(u<0||v<=u||v>=n0||seen[(usz)u][(usz)v])return -1;seen[(usz)u][(usz)v]=true;seen[(usz)v][(usz)u]=true;edges[i][0]=u;edges[i][1]=v;}
    int[4] edge_res;for(usz i=0;i<4;i++)edge_res[i]=-1;long[4][2] wedge;bool[4] valid;bool[4] closed;long total=0;long[84] staged;usz at=0,tape=4+2*m;
    for(usz ti=0;ti<m;ti++){
        usz t=ti+1,rec=tape+ti*stride;
        for(usz s=0;s<sw;s++)if(valid[s]&&wedge[s][0]==edges[ti][0]&&wedge[s][1]==edges[ti][1])closed[s]=true;
        long draw=input[rec],slot0=input[rec+1],limit=power((int)t,se),threshold=limit-power((int)t-1,se);if(draw<0||draw>=limit)return -1;bool update=draw<threshold;long[4][2] fresh;usz fresh_count=0,removed_count=0;
        if(update){if(slot0<0||slot0>=(long)se)return -1;usz slot=(usz)slot0;int old_id=edge_res[slot];if(old_id>=0)for(usz j=0;j<se;j++)if(j!=slot&&edge_res[j]>=0){long[2] old_wedge;if(make_wedge(edges[(usz)old_id],edges[(usz)edge_res[j]],old_wedge))removed_count++;}edge_res[slot]=(int)ti;for(usz j=0;j<se;j++)if(j!=slot&&edge_res[j]>=0){long[2] result;if(make_wedge(edges[ti],edges[(usz)edge_res[j]],result)){fresh[fresh_count][0]=result[0];fresh[fresh_count][1]=result[1];fresh_count++;}}}else if(slot0!=0)return -1;
        total+=(long)fresh_count-(long)removed_count;if(total<0)return -1;
        for(usz s=0;s<sw;s++){long wd=input[rec+2+2*s],pick=input[rec+3+2*s];if(fresh_count>0){if(wd<0||wd>=total)return -1;if(wd<(long)fresh_count){if(pick<0||pick>=(long)fresh_count)return -1;wedge[s][0]=fresh[(usz)pick][0];wedge[s][1]=fresh[(usz)pick][1];valid[s]=true;closed[s]=false;}else if(pick!=0)return -1;}else if(wd!=0||pick!=0)return -1;}
        long hits=0;for(usz s=0;s<sw;s++)if(closed[s])hits++;staged[at]=total;at++;staged[at]=(3*hits*1000000)/(long)sw;at++;staged[at]=(hits*(long)t*(long)t*total*1000000)/((long)sw*(long)se*(long)(se-1));at++;
    }
    usz bytes=24*m;if(output==null||capacity<bytes)return -2;for(usz i=0;i<at;i++)put_i64(output+8*i,staged[i]);return (long)bytes;
}
