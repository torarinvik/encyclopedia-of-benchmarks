module max_minimum_machine_load_lpt;
const usz N=16;const usz L=18;
fn void put64(char*o,usz p,long x){ulong b=(ulong)x;for(usz j=0;j<8;j+=1){o[p+j]=(char)(b&255);b>>=8;}}
long max_minimum_machine_load_lpt(long*in,usz len,char*out,usz cap) @export("max_minimum_machine_load_lpt"){
 if(in==null||len<3||len>L)return -1;long nr=in[0],mr=in[1];if(nr<1||nr>16||mr<1||mr>4||len!=2+(usz)nr)return -1;usz n=(usz)nr,m=(usz)mr;long p[16],order[16],assign[16],loads[4]={0};for(usz i=0;i<n;i+=1){p[i]=in[2+i];if(p[i]<1||p[i]>100)return -1;order[i]=(long)i;}usz bytes=8*(1+n+m);if(out==null||cap<bytes)return -2;
 for(usz i=1;i<n;i+=1){long key=order[i];usz j=i;while(j>0&&(p[(usz)key]>p[(usz)order[j-1]]||(p[(usz)key]==p[(usz)order[j-1]]&&key<order[j-1]))){order[j]=order[j-1];j-=1;}order[j]=key;}for(usz k=0;k<n;k+=1){usz job=(usz)order[k],machine=0;for(usz j=1;j<m;j+=1)if(loads[j]<loads[machine])machine=j;assign[job]=(long)machine;loads[machine]+=p[job];}long low=loads[0];for(usz j=1;j<m;j+=1)if(loads[j]<low)low=loads[j];put64(out,0,low);for(usz i=0;i<n;i+=1)put64(out,8*(1+i),assign[i]);for(usz j=0;j<m;j+=1)put64(out,8*(1+n+j),loads[j]);return (long)bytes;
}
