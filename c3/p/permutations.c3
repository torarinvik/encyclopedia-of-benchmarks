module permutations;
fn uint mix(uint h,uint8 b){return (h^b)*16777619;}
fn bool next_perm(int* a,usz n){usz i=n-1;while(i>0&&a[i-1]>=a[i])i--;if(i==0)return false;usz j=n-1;while(a[j]<=a[i-1])j--;int t=a[i-1];a[i-1]=a[j];a[j]=t;usz l=i;usz r=n-1;while(l<r){t=a[l];a[l]=a[r];a[r]=t;l++;r--;}return true;}
fn long permutations(long* v,usz n) @export("permutations"){if(v==null||n<2||n>7||v[0]<1||v[0]>6||n!=(usz)v[0]+1)return -1;usz count=(usz)v[0];int[6] a;for(usz i=0;i<count;i++){if(v[i+1]< -2147483648||v[i+1]>2147483647)return -1;a[i]=(int)v[i+1];if(i>0&&a[i-1]>=a[i])return -1;}uint h=2166136261;while(true){for(usz i=0;i<count;i++){uint u=(uint)a[i];for(usz b=0;b<4;b++)h=mix(h,(uint8)(u>>(8*b)));}h=mix(h,255);if(!next_perm(&a[0],count))break;}return (long)h;}
