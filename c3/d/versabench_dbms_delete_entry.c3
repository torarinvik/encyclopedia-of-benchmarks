module versabench_dbms_delete_entry;
const MAXW=181;
fn bool valid(long* b){for(usz d=0;d<4;d++)if(b[d]<-8||b[d]>8||b[4+d]<-8||b[4+d]>8||b[d]>=b[4+d])return false;return true;}
fn bool hit(long* b,long* q){for(usz d=0;d<4;d++)if(q[d]>b[4+d]||b[d]>q[4+d])return false;return true;}
fn void uni(long* x,usz n,usz stride,long* o){for(usz d=0;d<4;d++){o[d]=x[d];o[4+d]=x[4+d];}for(usz i=1;i<n;i++)for(usz d=0;d<4;d++){if(x[i*stride+d]<o[d])o[d]=x[i*stride+d];if(x[i*stride+4+d]>o[4+d])o[4+d]=x[i*stride+4+d];}}
fn void put(u8* o,usz w,long x){ulong u=(ulong)x;for(usz b=0;b<8;b++)o[w*8+b]=(u8)((u>>(8*b))&255);}
fn long versabench_dbms_delete_entry(long* v,usz n,u8* output,usz cap) @export("versabench_dbms_delete_entry"){
 if(v==null||n<10||n>190)return -1;long cv=v[0];if(cv<1||cv>4)return -1;usz nc=(usz)cv;long[8] q;for(usz d=0;d<8;d++)q[d]=v[1+d];if(!valid(&q[0]))return -1;
 long[4][4][8] boxes;long[4][4] ids;long[4][8] mbr;usz[4] counts;bool[32] seen;for(usz i=0;i<32;i++)seen[i]=false;usz p=9;
 for(usz c=0;c<nc;c++){if(p+9>n)return -1;long rv=v[p];p++;if(rv<1||rv>4||p+8+(usz)rv*9>n)return -1;counts[c]=(usz)rv;for(usz d=0;d<8;d++)mbr[c][d]=v[p+d];p+=8;if(!valid(&mbr[c][0]))return -1;for(usz r=0;r<counts[c];r++){for(usz d=0;d<8;d++)boxes[c][r][d]=v[p+d];p+=8;ids[c][r]=v[p];p++;if(!valid(&boxes[c][r][0])||ids[c][r]<0||ids[c][r]>=32||seen[(usz)ids[c][r]])return -1;seen[(usz)ids[c][r]]=true;}long[8] actual;uni(&boxes[c][0][0],counts[c],8,&actual[0]);for(usz d=0;d<8;d++)if(actual[d]!=mbr[c][d])return -1;}
 if(p!=n)return -1;long[4][4][8] kept;long[4][4] kid;long[4][8] kmbr;usz[4] kc;usz rem=0;
 for(usz c=0;c<nc;c++){usz k=0;for(usz r=0;r<counts[c];r++){if(hit(&mbr[c][0],&q[0])&&hit(&boxes[c][r][0],&q[0]))continue;for(usz d=0;d<8;d++)kept[c][k][d]=boxes[c][r][d];kid[c][k]=ids[c][r];k++;}if(k>0){kc[rem]=k;for(usz r=0;r<k;r++){for(usz d=0;d<8;d++)kept[rem][r][d]=kept[c][r][d];kid[rem][r]=kid[c][r];}uni(&kept[rem][0][0],k,8,&kmbr[rem][0]);rem++;}}
 long[MAXW] w;usz x=0;w[x]=(long)rem;x++;for(usz c=0;c<rem;c++){w[x]=(long)kc[c];x++;for(usz d=0;d<8;d++){w[x]=kmbr[c][d];x++;}for(usz r=0;r<kc[c];r++){for(usz d=0;d<8;d++){w[x]=kept[c][r][d];x++;}w[x]=kid[c][r];x++;}}
 usz bytes=x*8;if(output==null||cap<bytes)return -2;for(usz i=0;i<x;i++)put(output,i,w[i]);return (long)bytes;
}
