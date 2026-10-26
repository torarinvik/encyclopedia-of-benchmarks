module closest_substring_center;
fn long closest_substring_center(long*x,usz length,char*out,usz cap) @export("closest_substring_center"){
 if(x==null)return -2;if(length<4||length>44)return -1;long nv=x[0],mv=x[1],lv=x[2],qv=x[3];if(nv<1||nv>4||mv<1||mv>10||lv<1||lv>8||lv>mv||(qv!=2&&qv!=3)||length!=4+(usz)nv*(usz)mv)return -1;
 usz n=(usz)nv,m=(usz)mv,l=(usz)lv,q=(usz)qv;for(usz i=4;i<length;i++)if(x[i]<0||x[i]>=qv)return -1;usz total=1;for(usz i=0;i<l;i++)total*=q;usz best=l+1;usz[8] bc,cand;
 for(usz code=0;code<total;code++){usz v=code;for(usz p=l;p>0;p--){cand[p-1]=v%q;v/=q;}usz radius=0;for(usz row=0;row<n;row++){usz rb=l+1;for(usz st=0;st+l<=m;st++){usz d=0;for(usz j=0;j<l;j++)if((long)cand[j]!=x[4+row*m+st+j])d++;if(d<rb)rb=d;}if(rb>radius)radius=rb;}if(radius<best){best=radius;for(usz j=0;j<l;j++)bc[j]=cand[j];}}
 usz bytes=8*(l+1);if(cap<bytes||out==null)return -2;ulong z=(ulong)best;for(usz b=0;b<8;b++)out[b]=(char)((z>>(8*b))&255ul);for(usz j=0;j<l;j++){z=(ulong)bc[j];for(usz b=0;b<8;b++)out[8*(j+1)+b]=(char)((z>>(8*b))&255ul);}return (long)bytes;
}
