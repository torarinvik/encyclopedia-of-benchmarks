module static_rectangle_add_rectangle_sum;

const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_COORDS = 128;
const usz STRIDE = 129;
const usz GRID = MAX_COORDS * MAX_COORDS;
const usz PREFIX = STRIDE * STRIDE;
const long MOD = 998244353;

fn usz lower(long[MAX_COORDS]* a, usz n, long value) {
    usz lo=0, hi=n;
    while (lo<hi) { usz mid=lo+(hi-lo)/2; if(a[mid]<value) lo=mid+1; else hi=mid; }
    return lo;
}

fn void unique_sort(long[MAX_COORDS]* a, usz* n) {
    for (usz i=1;i<*n;i+=1) { long value=a[i]; usz j=i; while(j>0 && a[j-1]>value){a[j]=a[j-1];j-=1;} a[j]=value; }
    usz out=0;
    for (usz i=0;i<*n;i+=1) if(out==0 || a[i]!=a[out-1]) {a[out]=a[i];out+=1;}
    *n=out;
}

fn void put64(uint8* output, usz at, long value) {
    uint64 bits=(uint64)value;
    for (usz b=0;b<8;b+=1) output[at+b]=(uint8)(bits>>(8*b));
}

fn long static_rectangle_add_rectangle_sum(long* input, usz length, uint8* output,
                                            usz capacity) @export("static_rectangle_add_rectangle_sum") {
    if(input==null || length<2 || length>291) return -1;
    long n64=input[0], q64=input[1];
    if(n64<1 || n64>32 || q64<0 || q64>32) return -1;
    usz n=(usz)n64,q=(usz)q64;
    if(length!=2+5*n+4*q) return -1;
    long[MAX_N] ul,ud,ur,uu,uw;
    long[MAX_Q] ql,qd,qr,qu;
    long[MAX_COORDS] xs,ys;
    usz nx=0,ny=0,off=2;
    for(usz i=0;i<n;i+=1){
        ul[i]=input[off];ud[i]=input[off+1];ur[i]=input[off+2];uu[i]=input[off+3];uw[i]=input[off+4];off+=5;
        if(ul[i]<0 || ul[i]>=ur[i] || ur[i]>1000000 || ud[i]<0 || ud[i]>=uu[i] || uu[i]>1000000 || uw[i]<0 || uw[i]>=MOD) return -1;
        xs[nx]=ul[i];xs[nx+1]=ur[i];ys[ny]=ud[i];ys[ny+1]=uu[i];nx+=2;ny+=2;
    }
    for(usz i=0;i<q;i+=1){
        ql[i]=input[off];qd[i]=input[off+1];qr[i]=input[off+2];qu[i]=input[off+3];off+=4;
        if(ql[i]<0 || ql[i]>=qr[i] || qr[i]>1000000 || qd[i]<0 || qd[i]>=qu[i] || qu[i]>1000000) return -1;
        xs[nx]=ql[i];xs[nx+1]=qr[i];ys[ny]=qd[i];ys[ny+1]=qu[i];nx+=2;ny+=2;
    }
    unique_sort(&xs,&nx);unique_sort(&ys,&ny);
    long[GRID] diff=zeroed; long[PREFIX] prefix=zeroed;
    for(usz k=0;k<n;k+=1){
        usz x0=lower(&xs,nx,ul[k]),x1=lower(&xs,nx,ur[k]),y0=lower(&ys,ny,ud[k]),y1=lower(&ys,ny,uu[k]);
        diff[x0*MAX_COORDS+y0]+=uw[k];diff[x1*MAX_COORDS+y0]-=uw[k];diff[x0*MAX_COORDS+y1]-=uw[k];diff[x1*MAX_COORDS+y1]+=uw[k];
    }
    for(usz i=0;i<nx;i+=1)for(usz j=0;j<ny;j+=1){
        usz at=i*MAX_COORDS+j;long v=diff[at];if(i>0)v+=diff[(i-1)*MAX_COORDS+j];if(j>0)v+=diff[i*MAX_COORDS+j-1];if(i>0 && j>0)v-=diff[(i-1)*MAX_COORDS+j-1];diff[at]=v;
    }
    for(usz i=0;i+1<nx;i+=1)for(usz j=0;j+1<ny;j+=1){
        long val=diff[i*MAX_COORDS+j]%MOD,dx=(xs[i+1]-xs[i])%MOD,dy=(ys[j+1]-ys[j])%MOD;
        long cell=val*(dx*dy%MOD)%MOD;usz at=(i+1)*STRIDE+j+1;
        long sum=(cell+prefix[i*STRIDE+j+1]+prefix[(i+1)*STRIDE+j]-prefix[i*STRIDE+j])%MOD;if(sum<0)sum+=MOD;prefix[at]=sum;
    }
    long[MAX_Q] answer;
    for(usz k=0;k<q;k+=1){
        usz x0=lower(&xs,nx,ql[k]),x1=lower(&xs,nx,qr[k]),y0=lower(&ys,ny,qd[k]),y1=lower(&ys,ny,qu[k]);
        long v=prefix[x1*STRIDE+y1]-prefix[x0*STRIDE+y1]-prefix[x1*STRIDE+y0]+prefix[x0*STRIDE+y0];v%=MOD;if(v<0)v+=MOD;answer[k]=v;
    }
    usz bytes=8*q;if(output==null || capacity<bytes)return -2;
    for(usz k=0;k<q;k+=1)put64(output,8*k,answer[k]);
    return (long)bytes;
}
