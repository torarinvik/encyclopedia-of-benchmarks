module closest_string_center;

fn long closest_string_center(long* x, usz length, char* out, usz cap) @export("closest_string_center") {
    if(x==null)return -2;if(length<3||length>51)return -1;long nv=x[0],mv=x[1],qv=x[2];
    if(nv<1||nv>6||mv<1||mv>8||(qv!=2&&qv!=3)||length!=3+(usz)nv*(usz)mv)return -1;
    usz n=(usz)nv,m=(usz)mv,q=(usz)qv;for(usz i=3;i<length;i++)if(x[i]<0||x[i]>=qv)return -1;
    usz total=1;for(usz i=0;i<m;i++)total*=q;usz best=m+1;usz[8] bestc,candidate;
    for(usz code=0;code<total;code++){usz v=code;for(usz p=m;p>0;p--){candidate[p-1]=v%q;v/=q;}usz radius=0;
        for(usz row=0;row<n;row++){usz d=0;for(usz col=0;col<m;col++)if((long)candidate[col]!=x[3+row*m+col])d++;if(d>radius)radius=d;}
        if(radius<best){best=radius;for(usz j=0;j<m;j++)bestc[j]=candidate[j];}}
    usz bytes=8*(m+1);if(cap<bytes||out==null)return -2;ulong value=(ulong)best;for(usz b=0;b<8;b++)out[b]=(char)((value>>(8*b))&255ul);
    for(usz j=0;j<m;j++){value=(ulong)bestc[j];for(usz b=0;b<8;b++)out[8*(j+1)+b]=(char)((value>>(8*b))&255ul);}return (long)bytes;
}
