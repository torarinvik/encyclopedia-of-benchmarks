module pareto_optimization;
const ulong OFFSET=0xcbf29ce484222325;const ulong PRIME=0x100000001b3;
fn ulong feed(ulong h,long v){ulong bits=(ulong)v;for(uint s=0;s<64;s+=8)h=(h^(ulong)(uint8)(bits>>s))*PRIME;return h;}
fn long pareto_optimization(long* a,usz len) @export("pareto_optimization"){
 if(a==null||len<2||len>514)return -1;long r64=a[0],c64=a[1];if(r64<1||r64>64||c64<1||c64>8||len!=(usz)(2+r64*c64))return -1;usz r=(usz)r64,c=(usz)c64;
 for(usz k=0;k<r*c;k++)if(a[2+k]<-1000||a[2+k]>1000)return -1;bool[64] keep;long kept=0;
 for(usz i=0;i<r;i++){keep[i]=true;for(usz j=0;j<r;j++){if(i==j)continue;bool ge=true,gt=false;for(usz x=0;x<c;x++){long l=a[2+j*c+x],v=a[2+i*c+x];if(l<v)ge=false;if(l>v)gt=true;}if(ge&&(gt||j<i)){keep[i]=false;break;}}if(keep[i])kept++;}
 ulong h=feed(OFFSET,kept);h=feed(h,c64);for(usz i=0;i<r;i++)if(keep[i])for(usz x=0;x<c;x++)h=feed(h,a[2+i*c+x]);return (long)(h&0x7fffffffffffffff);
}
