module nbench_resource_assignment;
const usz NMAX=8;
const usz CELLS=64;
const usz MAX_ADJUST=2048;
fn usz first(long* a, uint8* mark, usz n) {
    for(usz x=0;x<n*n;x+=1)mark[x]=0;usz total=0;
    while(true){usz made=0;
        for(usz i=0;i<n;i+=1){usz count=0,sel=0;for(usz j=0;j<n;j+=1)if(a[i*n+j]==0&&mark[i*n+j]==0){count+=1;sel=j;}if(count==1){made+=1;total+=1;mark[i*n+sel]=1;for(usz k=0;k<n;k+=1)if(k!=i&&a[k*n+sel]==0)mark[k*n+sel]=2;}}
        for(usz j=0;j<n;j+=1){usz count=0,sel=0;for(usz i=0;i<n;i+=1)if(a[i*n+j]==0&&mark[i*n+j]==0){count+=1;sel=i;}if(count==1){made+=1;total+=1;mark[sel*n+j]=1;for(usz k=0;k<n;k+=1)if(k!=j&&a[sel*n+k]==0)mark[sel*n+k]=2;}}
        if(made==0)break;
    }
    if(total==n)return total;
    for(usz i=0;i<n;i+=1){usz sel=n;for(usz j=0;j<n;j+=1)if(a[i*n+j]==0&&mark[i*n+j]==0){sel=j;break;}if(sel<n){mark[i*n+sel]=1;total+=1;for(usz k=0;k<n;k+=1)if(k!=sel&&a[i*n+k]==0)mark[i*n+k]=2;for(usz k=0;k<n;k+=1)if(k!=i&&a[k*n+sel]==0)mark[k*n+sel]=2;}}
    return total;
}
fn bool second(long* a,uint8* mark,usz n){uint8[NMAX] rows;uint8[NMAX] cols;for(usz i=0;i<n;i+=1){rows[i]=0;cols[i]=0;bool found=false;for(usz j=0;j<n;j+=1)if(mark[i*n+j]==1){found=true;break;}if(!found)rows[i]=1;}
    while(true){usz added=0;for(usz i=0;i<n;i+=1)if(rows[i]==1)for(usz j=0;j<n;j+=1)if(a[i*n+j]==0)cols[j]=1;for(usz j=0;j<n;j+=1)if(cols[j]==1)for(usz i=0;i<n;i+=1)if(mark[i*n+j]==1&&rows[i]!=1){rows[i]=1;added+=1;}if(added==0)break;}
    long smallest=9223372036854775807;for(usz i=0;i<n;i+=1)if(rows[i]==1)for(usz j=0;j<n;j+=1)if(cols[j]==0&&a[i*n+j]<smallest)smallest=a[i*n+j];if(smallest==9223372036854775807)return false;
    for(usz i=0;i<n;i+=1)for(usz j=0;j<n;j+=1){if(rows[i]==1&&cols[j]==0)a[i*n+j]-=smallest;else if(rows[i]==0&&cols[j]==1)a[i*n+j]+=smallest;}return true;
}
fn long nbench_resource_assignment(long* input,usz length,char* output,usz capacity) @export("nbench_resource_assignment") {
    if(input==null||length<2||length>66)return -1;long raw=input[0];if(raw<1||raw>8)return -1;usz n=(usz)raw;if(length!=1+n*n)return -1;
    long[CELLS] a;for(usz i=0;i<n*n;i+=1){if(input[i+1]<0||input[i+1]>1000)return -1;a[i]=input[i+1];}
    for(usz i=0;i<n;i+=1){long m=a[i*n];for(usz j=1;j<n;j+=1)if(a[i*n+j]<m)m=a[i*n+j];for(usz j=0;j<n;j+=1)a[i*n+j]-=m;}
    for(usz j=0;j<n;j+=1){long m=a[j];for(usz i=1;i<n;i+=1)if(a[i*n+j]<m)m=a[i*n+j];if(m!=0)for(usz i=0;i<n;i+=1)a[i*n+j]-=m;}
    uint8[CELLS] mark;for(usz i=0;i<CELLS;i+=1)mark[i]=0;bool done=false;for(usz iter=0;iter<=MAX_ADJUST;iter+=1){if(first(&a[0],&mark[0],n)==n){done=true;break;}if(!second(&a[0],&mark[0],n))return -1;}if(!done)return -1;
    int32[NMAX] result;bool[NMAX] seen;for(usz i=0;i<NMAX;i+=1)seen[i]=false;for(usz i=0;i<n;i+=1){usz col=n;for(usz j=0;j<n;j+=1)if(mark[i*n+j]==1){if(col!=n)return -1;col=j;}if(col==n||seen[col])return -1;result[i]=(int32)col;seen[col]=true;}
    usz bytes=n*4;if(output==null||capacity<bytes)return -2;for(usz i=0;i<n;i+=1){uint x=(uint)result[i];for(usz b=0;b<4;b+=1)output[i*4+b]=(char)(x>>(b*8));}return (long)bytes;
}
