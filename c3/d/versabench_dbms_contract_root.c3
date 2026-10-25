module versabench_dbms_contract_root;
fn void put(u8*o,usz w,long x){ulong u=(ulong)x;for(usz b=0;b<8;b++)o[w*8+b]=(u8)((u>>(8*b))&255);}
fn long versabench_dbms_contract_root(long*v,usz n,u8*out,usz cap) @export("versabench_dbms_contract_root"){
 if(v==null||n<3||n>12)return -1;long nv=v[0];if(nv<1||nv>5||n!=1+2*(usz)nv)return -1;usz count=(usz)nv;long[5] levels;long[5] entries;
 for(usz i=0;i<count;i++){levels[i]=v[1+2*i];entries[i]=v[2+2*i];if(levels[i]<0||levels[i]>4||entries[i]<0||entries[i]>4)return -1;if(i+1<count&&(levels[i]==0||entries[i]!=1||levels[i+1]!=levels[i]-1))return -1;}
 if(levels[count-1]>0&&entries[count-1]==1)return -1;if(levels[count-1]>0&&entries[count-1]==0&&count!=1)return -1;usz root=0;usz promotions=0;while(levels[root]>0&&entries[root]==1){root++;promotions++;}long fl=levels[root];long fc=entries[root];if(fl>0&&fc==0){fl=0;fc=0;}if(out==null||cap<24)return -2;put(out,0,(long)promotions);put(out,1,fl);put(out,2,fc);return 24;
}
