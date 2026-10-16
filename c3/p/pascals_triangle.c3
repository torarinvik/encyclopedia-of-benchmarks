module pascals_triangle;
fn long pascals_triangle(long* v,usz n) @export("pascals_triangle"){if(v==null||n!=1||v[0]<1||v[0]>31)return -1;usz rows=(usz)v[0];long[31] a;a[0]=1;for(usz r=1;r<rows;r++){a[r]=1;usz j=r;while(j>1){j-=1;a[j]+=a[j-1];}}long h=0;for(usz i=0;i<rows;i++)h=(h*31+a[i])%1000000007;return h;}
