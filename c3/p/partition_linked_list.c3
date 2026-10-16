module partition_linked_list;
const long MODULUS=1000000007;
const long BASE=2000000003;
fn long partition_linked_list(long* v,usz n) @export("partition_linked_list"){if(v==null||n<2||n>66||v[0]<0||v[0]>64||n!=(usz)v[0]+2||v[1]<-2147483648||v[1]>2147483647)return -1;usz count=(usz)v[0];long[64] less;long[64] greater;usz l=0;usz g=0;for(usz i=0;i<count;i++){long x=v[i+2];if(x< -2147483648||x>2147483647)return -1;if(x<v[1])less[l++]=x;else greater[g++]=x;}long h=0;for(usz i=0;i<l;i++)h=(h*BASE+less[i]+2147483648)%MODULUS;for(usz i=0;i<g;i++)h=(h*BASE+greater[i]+2147483648)%MODULUS;return h;}
