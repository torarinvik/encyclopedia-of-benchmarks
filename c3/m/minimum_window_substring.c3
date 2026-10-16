module minimum_window_substring;
const usz MAX_TEXT=128;
fn long minimum_window_substring(long* v,usz n,char* out,usz cap) @export("minimum_window_substring") {
 if(v==null||n<3||n>258||v[0]<0||v[0]>(long)MAX_TEXT)return -1;usz a=(usz)v[0];if(n<a+2)return -1;long mm=v[a+1];if(mm<1||mm>(long)MAX_TEXT)return -1;usz m=(usz)mm;if(n!=a+m+2)return -1;
 int need[128]={};for(usz i=0;i<a;i++){if(v[i+1]<0||v[i+1]>127)return -1;}for(usz i=0;i<m;i++){long c=v[a+2+i];if(c<0||c>127)return -1;need[(usz)c]++;}
 usz left=0,best=a+1,start=0;long missing=(long)m;for(usz right=0;right<a;right++){usz c=(usz)v[right+1];if(need[c]>0)missing--;need[c]--;while(missing==0){usz len=right-left+1;if(len<best){best=len;start=left;}usz x=(usz)v[left+1];need[x]++;left++;if(need[x]>0)missing++;}}
 if(best==a+1)return 0;if(best>cap||(best>0&&out==null))return -2;for(usz i=0;i<best;i++)out[i]=(char)v[start+1+i];return (long)best;
}
