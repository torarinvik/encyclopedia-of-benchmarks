module number_container_system;
fn long number_container_system(long*v,usz n,char*out,usz cap) @export("number_container_system") {
 if(v==null||n<1||v[0]<0||v[0]>32||n!=1+3*(usz)v[0])return -1;
 long[64] values;bool[64] present;char[128] b;usz used=0;
 for(usz i=0;i<(usz)v[0];i++){long op=v[1+3*i],a=v[2+3*i],value=v[3+3*i];if(op==0){if(a<0||a>63||value< -100||value>100)return -1;values[(usz)a]=value;present[(usz)a]=true;}else if(op==1){if(a< -100||a>100||value!=0)return -1;long found=-1;for(usz j=0;j<64;j++)if(present[j]&&values[j]==a){found=(long)j;break;}if(used>0)b[used++]=',';if(found<0)b[used++]='-';usz x=(usz)(found<0?-found:found);char[3] d;usz k=0;do{d[k++]=(char)('0'+x%10);x/=10;}while(x>0);while(k>0)b[used++]=d[--k];}else return -1;}
 if(used>cap||(used>0&&out==null))return -2;for(usz i=0;i<used;i++)out[i]=b[i];return (long)used;
}
