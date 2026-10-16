module max_consecutive_ones_iii;
fn long max_consecutive_ones_iii(long* a, usz len) @export("max_consecutive_ones_iii") {
 if(a==null || len<3 || len>1026 || a[0]<1 || a[0]>1024 || len!=(usz)a[0]+2 || a[1]<0 || a[1]>a[0]) return -2;
 usz n=(usz)a[0], left=0, zeros=0, best=0; for(usz i=0;i<n;i++) if(a[i+2]!=0 && a[i+2]!=1) return -2;
 for(usz r=0;r<n;r++){if(a[r+2]==0) zeros++; while(zeros>(usz)a[1]){if(a[left+2]==0) zeros--; left++;} if(r-left+1>best) best=r-left+1;} return (long)best; }
