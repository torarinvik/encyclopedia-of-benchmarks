module diff_views_of_binary_tree;
const usz N = 1023;
fn long diff_views_of_binary_tree(long* a, usz n, long root, long view, long* out, usz cap) @export("diff_views_of_binary_tree") {
 if(n>N||view<0||view>3)return -1;
 if(n==0)return root==-1?0:-1;
 if(a==null||root<0||(usz)root>=n)return -1;
 if(out==null||cap<n)return -2;
 usz[N] parents;for(usz i=0;i<n;i++)parents[i]=0;
 for(usz i=0;i<n;i++){long v=a[3*i];long l=a[3*i+1];long r=a[3*i+2];if(v< -2147483648||v>2147483647||l< -1||r< -1||(l>=0&&(usz)l>=n)||(r>=0&&(usz)r>=n))return -1;if(l>=0&&++parents[(usz)l]>1)return -1;if(r>=0&&++parents[(usz)r]>1)return -1;}
 if(parents[(usz)root]!=0)return -1;for(usz i=0;i<n;i++)if(i!=(usz)root&&parents[i]!=1)return -1;
 usz[N] q,depth;long[N] col;bool[N] seen;long[N] fd,ld;long[2*N+1] fc,lc;
 for(usz i=0;i<N;i++){seen[i]=false;fd[i]=-9223372036854775807;ld[i]=-9223372036854775807;}
 for(usz i=0;i<2*N+1;i++){fc[i]=-9223372036854775807;lc[i]=-9223372036854775807;}
 usz head=0;usz tail=1;usz reached=0;usz maxd=0;q[0]=(usz)root;depth[(usz)root]=0;col[(usz)root]=0;seen[(usz)root]=true;long minc=0;long maxc=0;
 while(head<tail){usz u=q[head++];usz d=depth[u];long c=col[u];long v=a[3*u];reached++;if(d>maxd)maxd=d;if(c<minc)minc=c;if(c>maxc)maxc=c;if(fd[d]==-9223372036854775807)fd[d]=v;ld[d]=v;usz s=(usz)(c+(long)N);if(fc[s]==-9223372036854775807)fc[s]=v;lc[s]=v;long l=a[3*u+1];long r=a[3*u+2];if(l>=0){usz x=(usz)l;if(seen[x]||tail>=n)return -1;seen[x]=true;q[tail]=x;depth[x]=d+1;col[x]=c-1;tail++;}if(r>=0){usz x=(usz)r;if(seen[x]||tail>=n)return -1;seen[x]=true;q[tail]=x;depth[x]=d+1;col[x]=c+1;tail++;}}
 if(reached!=n)return -1;usz w=0;if(view<2){for(usz d=0;d<=maxd;d++){long v=view==0?ld[d]:fd[d];if(v!=-9223372036854775807){out[w]=v;w++;}}}else{for(long c=minc;c<=maxc;c++){usz s=(usz)(c+(long)N);long v=view==2?fc[s]:lc[s];if(v!=-9223372036854775807){out[w]=v;w++;}}}return (long)w;
}
