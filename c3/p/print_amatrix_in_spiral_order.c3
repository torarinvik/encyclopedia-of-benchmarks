module print_amatrix_in_spiral_order;
fn uint feed(uint h, long x) { uint u=(uint)(int)x; for(uint s=0;s<32;s+=8) h=(h^((u>>s)&255))*16777619; return h; }
fn long print_amatrix_in_spiral_order(long* v, ulong n) @export("print_amatrix_in_spiral_order") {
 if(v==null||n<3||n>66||v[0]<1||v[0]>8||v[1]<1||v[1]>8||n!=2+(ulong)(v[0]*v[1]))return -1;
 ulong rows=(ulong)v[0], cols=(ulong)v[1];for(ulong i=2;i<n;i++)if(v[i]<-2147483648||v[i]>2147483647)return -1;
 ulong t=0,b=rows-1,l=0,r=cols-1;uint h=2166136261;while(t<=b&&l<=r){for(ulong c=l;c<=r;c++)h=feed(h,v[2+t*cols+c]);t++;for(ulong y=t;y<=b;y++)h=feed(h,v[2+y*cols+r]);if(r==0)break;r--;if(t<=b){for(ulong c=r+1;c>l;c--)h=feed(h,v[2+b*cols+c-1]);if(b==0)break;b--;}if(l<=r){for(ulong y=b+1;y>t;y--)h=feed(h,v[2+(y-1)*cols+l]);l++;}}return (long)h;
}
