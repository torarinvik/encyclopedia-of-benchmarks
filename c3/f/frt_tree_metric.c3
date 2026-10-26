module frt_tree_metric;

fn bool within(long d, long beta, int level) {
    if (level >= 0) return d * 1024 <= beta * (1l << level);
    return d * 1024 * (1l << -level) <= beta;
}
fn void put_i64(uint8* out, long value) {
    ulong bits=(ulong)value;
    for(usz b=0;b<8;b++)out[b]=(uint8)(bits>>(8*b));
}

fn long frt_tree_metric(long* input, usz length, uint8* output, usz capacity) @export("frt_tree_metric") {
    if(input==null||length<8||length>74)return -1;
    long n0=input[0], beta=input[1];
    if(n0<2||n0>8||beta<1024||beta>2047)return -1;
    usz n=(usz)n0; if(length!=2+n+n*n)return -1;
    usz[8] perm; bool[8] seen;
    for(usz i=0;i<n;i++){long p=input[2+i];if(p<0||p>=n0||seen[(usz)p])return -1;seen[(usz)p]=true;perm[i]=(usz)p;}
    long[8][8] d; long maxd=0; usz base=2+n;
    for(usz i=0;i<n;i++)for(usz j=0;j<n;j++){long x=input[base+i*n+j];if(x<0||x>255||(i==j&&x!=0)||(i!=j&&x==0))return -1;d[i][j]=x;if(x>maxd)maxd=x;}
    for(usz i=0;i<n;i++)for(usz j=0;j<n;j++){if(d[i][j]!=d[j][i])return -1;for(usz k=0;k<n;k++)if(d[i][j]>d[i][k]+d[k][j])return -1;}
    int high=0;while((1l<<high)<maxd)high++;
    long[64] staged; usz[256] clusters; usz[256] next; usz count=1;clusters[0]=(1u<<n)-1;
    for(int level=high;level>=-10;level--){usz next_count=0;long td=1l<<(level+13);
        for(usz ci=0;ci<count;ci++){usz remaining=clusters[ci],done=0;
            while(remaining!=0){usz center=n;for(usz p=0;p<n;p++)if((remaining&(1u<<perm[p]))!=0){center=perm[p];break;}if(center==n)return -1;
                usz child=0;for(usz v=0;v<n;v++)if((remaining&(1u<<v))!=0&&within(d[center][v],beta,level))child|=1u<<v;if(child==0)child=1u<<center;
                for(usz u=0;u<n;u++)if((done&(1u<<u))!=0)for(usz v=0;v<n;v++)if((child&(1u<<v))!=0){staged[u*n+v]=td;staged[v*n+u]=td;}
                done|=child;remaining&=~child;if(next_count>=256)return -1;next[next_count]=child;next_count++;
            }
        }for(usz i=0;i<next_count;i++)clusters[i]=next[i];count=next_count;
    }
    usz bytes=8*n*n;if(output==null||capacity<bytes)return -2;for(usz i=0;i<n*n;i++)put_i64(output+8*i,staged[i]);return (long)bytes;
}
