module k_median_p1_local_search;
fn void put64(char*o,long x){ulong b=(ulong)x;for(usz i=0;i<8;i++)o[i]=(char)(b>>(8*i));}
fn long objective(long* d,int n,int*c,int k){long total=0;for(int i=0;i<n;i++){long best=9223372036854775807;for(int j=0;j<k;j++)if(d[i*12+c[j]]<best)best=d[i*12+c[j]];total+=best;}return total;}
fn void sort_centers(int*c,int k){for(int i=1;i<k;i++){int x=c[i],j=i;while(j>0&&c[j-1]>x){c[j]=c[j-1];j--;}c[j]=x;}}
fn bool lexless(int*a,int*b,int k){for(int i=0;i<k;i++){if(a[i]!=b[i])return a[i]<b[i];}return false;}
long k_median_p1_local_search(long*input,usz length,char*output,usz capacity) @export("k_median_p1_local_search") {
 if(input==null||length<2||length>150)return -1;long n0=input[0],k0=input[1];if(n0<2||n0>12||k0<1||k0>4||k0>n0||length!=2+(usz)(n0*n0+k0))return -1;int n=(int)n0,k=(int)k0;long[144] d=zeroed;usz p=2;
 for(int i=0;i<n;i++)for(int j=0;j<n;j++){long x=input[p++];if(x<0||x>1000)return -1;d[i*12+j]=x;}
 for(int i=0;i<n;i++)for(int j=0;j<n;j++){if(d[i*12+j]!=(i==j?0:d[i*12+j])||d[i*12+j]!=d[j*12+i]||(i!=j&&d[i*12+j]==0))return -1;for(int h=0;h<n;h++)if(d[i*12+j]>d[i*12+h]+d[h*12+j])return -1;}
 bool[12] selected=zeroed;int[4] centers=zeroed;for(int i=0;i<k;i++){long x=input[p++];if(x<0||x>=n||selected[(int)x])return -1;centers[i]=(int)x;selected[(int)x]=true;}sort_centers(&centers[0],k);long current=objective(&d[0],n,&centers[0],k);
 for(;;){long best=current;int[4] bestc=centers;bool have=false;for(int leave=0;leave<k;leave++)for(int enter=0;enter<n;enter++)if(!selected[enter]){int[4] cand=centers;cand[leave]=enter;sort_centers(&cand[0],k);long value=objective(&d[0],n,&cand[0],k);if(value<current&&(value<best||(value==best&&(!have||lexless(&cand[0],&bestc[0],k))))){best=value;bestc=cand;have=true;}}if(!have)break;for(int i=0;i<k;i++)selected[centers[i]]=false;centers=bestc;for(int i=0;i<k;i++)selected[centers[i]]=true;current=best;}
 usz bytes=8*(usz)(2+k);if(output==null||capacity<bytes)return -2;put64(output,current);put64(output+8,k);for(int i=0;i<k;i++)put64(output+16+8*i,centers[i]);return (long)bytes;
}
