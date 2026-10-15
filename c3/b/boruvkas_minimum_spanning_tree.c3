module boruvkas_minimum_spanning_tree;
const usz MAX_N=16;
fn usz root(usz* p, usz x) { while(p[x]!=x){p[x]=p[p[x]];x=p[x];}return x; }
fn long boruvkas_minimum_spanning_tree_impl(long* input, usz length) {
 if(input==null||length<2)return -1;long nv=input[0],mv=input[1];if(nv<2||nv>16||mv<nv-1||mv>64||mv>nv*(nv-1)/2)return -1;
 usz n=(usz)nv,m=(usz)mv;if(length!=2+3*m)return -1;long[256] w;for(usz i=0;i<256;i++)w[i]=9223372036854775807;
 for(usz k=0;k<m;k++){long u=input[2+3*k],v=input[3+3*k],x=input[4+3*k];if(u<1||u>nv||v<1||v>nv||u==v||x<1||x>100||w[((usz)u-1)*16+(usz)v-1]!=9223372036854775807)return -1;w[((usz)u-1)*16+(usz)v-1]=x;w[((usz)v-1)*16+(usz)u-1]=x;}
 usz[16] p;for(usz i=0;i<n;i++)p[i]=i;usz components=n;long total=0;
 while(components>1){long[16] bu,bv,bw;for(usz i=0;i<16;i++){bu[i]=-1;bv[i]=-1;bw[i]=9223372036854775807;}
  for(usz u=0;u<n;u++)for(usz v=u+1;v<n;v++){long x=w[u*16+v];if(x!=9223372036854775807){usz a=root(&p,u),b=root(&p,v);if(a!=b){if(x<bw[a]){bw[a]=x;bu[a]=(long)u;bv[a]=(long)v;}if(x<bw[b]){bw[b]=x;bu[b]=(long)u;bv[b]=(long)v;}}}}
  bool merged=false;for(usz r=0;r<n;r++)if(bu[r]>=0){usz a=root(&p,(usz)bu[r]),b=root(&p,(usz)bv[r]);if(a!=b){p[a]=b;components--;total+=bw[r];merged=true;}}if(!merged)return -1;
 }return total;
}
fn long boruvkas_minimum_spanning_tree(long* input, usz length) @export("boruvkas_minimum_spanning_tree") { return boruvkas_minimum_spanning_tree_impl(input,length); }
