module technology_mapping_minimum_area_tree_cover;
const int NMAX=31;const int INMAX=99;const int OUTMAX=256;const long INF=2305843009213693951;
fn void put_i64(char* out,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){out[offset+b]=(char)(bits&255);bits>>=8;}}
fn long technology_mapping_minimum_area_tree_cover(long* v,usz length,char* output,usz capacity) @export("technology_mapping_minimum_area_tree_cover") {
 if(v==null||length<9||length>INMAX||v[0]<1||v[0]>NMAX)return -1;int n=(int)v[0];if(length!=(usz)(6+3*n))return -1;
 long[5] cost={};for(int p=0;p<5;p++){cost[p]=v[1+p];if(cost[p]!=-1&&(cost[p]<1||cost[p]>1000000))return -1;}
 int[NMAX] kind={},left={},right={},parents={};
 for(int i=0;i<n;i++){usz at=(usz)(6+3*i);long k=v[at],l=v[at+1],r=v[at+2];if(k<0||k>2)return -1;kind[i]=(int)k;left[i]=(int)l;right[i]=(int)r;
  if(k==0){if(l!=-1||r!=-1)return -1;}else if(k==1){if(l<=i||l>=n||r!=-1)return -1;parents[(int)l]++;}else{if(l<=i||l>=n||r<=i||r>=n||l==r)return -1;parents[(int)l]++;parents[(int)r]++;}}
 if(parents[0]!=0)return -1;for(int i=1;i<n;i++)if(parents[i]!=1)return -1;
 long[NMAX] best={};int[NMAX] choice={};for(int i=0;i<NMAX;i++){best[i]=INF;choice[i]=-1;}
 for(int i=n-1;i>=0;i--){if(kind[i]==0){best[i]=0;continue;}int l=left[i],r=right[i];long cand;
  if(kind[i]==1){if(cost[0]>=0){cand=cost[0]+best[l];if(cand<INF&&cand<best[i]){best[i]=cand;choice[i]=0;}}}
  else{if(cost[1]>=0){cand=cost[1]+best[l]+best[r];if(cand<INF&&cand<best[i]){best[i]=cand;choice[i]=1;}}
   if(cost[2]>=0&&kind[l]==1){cand=cost[2]+best[left[l]]+best[r];if(cand<INF&&cand<best[i]){best[i]=cand;choice[i]=2;}}
   if(cost[3]>=0&&kind[r]==1){cand=cost[3]+best[l]+best[left[r]];if(cand<INF&&cand<best[i]){best[i]=cand;choice[i]=3;}}
   if(cost[4]>=0&&kind[l]==1&&kind[r]==1){cand=cost[4]+best[left[l]]+best[left[r]];if(cand<INF&&cand<best[i]){best[i]=cand;choice[i]=4;}}}}
 if(best[0]==INF)return -1;int[NMAX] mapping={};for(int i=0;i<n;i++)mapping[i]=kind[i]==0?-1:-3;int[2*NMAX] stack={};int top=0;if(kind[0]!=0)stack[top++]=0;
 while(top>0){int node=stack[--top],p=choice[node],l=left[node],r=right[node];mapping[node]=p;
  if(p==0)stack[top++]=l;else if(p==1){stack[top++]=l;stack[top++]=r;}else if(p==2){mapping[l]=-2;stack[top++]=left[l];stack[top++]=r;}else if(p==3){mapping[r]=-2;stack[top++]=l;stack[top++]=left[r];}else{mapping[l]=-2;mapping[r]=-2;stack[top++]=left[l];stack[top++]=left[r];}}
 usz bytes=(usz)(8*(n+1));if(output==null||capacity<bytes)return -2;char[OUTMAX] staged={};put_i64(staged,0,best[0]);for(int i=0;i<n;i++)put_i64(staged,(usz)(8*(i+1)),mapping[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
