module cbench_ispell_lookup_chain;

fn usz is_hash(long* a, usz n, usz mod) {
    uint h=0; usz first=n<4?n:4; usz i=0;
    for(;i<first;i++) h=(h<<8)|(a[i].uint()-32);
    for(;i<n;i++) h=((h<<5)|(h>>27))^(a[i].uint()-32);
    return h.usz()%mod;
}
fn long cbench_ispell_lookup_chain(long* a, usz len) @export("cbench_ispell_lookup_chain") {
    if(a==null||len<3||len>108||a[0]<1||a[0]>8||a[1]<1||a[1]>8||a[2]<0||a[2]>8)return -1;
    usz m=a[0].usz(),q=a[1].usz(),n=a[2].usz();if(len<3+q+m+2*n)return -1;
    usz h0=3+q,nx0=h0+m,l0=nx0+n,p=l0+n;
    for(usz j=0;j<q;j++)if(a[3+j]<97||a[3+j]>122)return -1;
    long[8] heads=zeroed,next=zeroed;usz[8] lens=zeroed,off=zeroed;
    for(usz b=0;b<m;b++){heads[b]=a[h0+b];if(heads[b]<-1||heads[b]>=n.long())return -1;}
    for(usz i=0;i<n;i++){next[i]=a[nx0+i];if(next[i]<-1||next[i]>=n.long()||a[l0+i]<1||a[l0+i]>8)return -1;lens[i]=a[l0+i].usz();if(p+lens[i]>len)return -1;off[i]=p;for(usz j=0;j<lens[i];j++)if(a[p+j]<97||a[p+j]>122)return -1;p+=lens[i];}
    if(p!=len)return -1;bool[8] seen=zeroed;usz count=0;
    for(usz b=0;b<m;b++){long x=heads[b];while(x!=-1){usz i=x.usz();if(seen[i])return -1;seen[i]=true;count++;if(is_hash(a+off[i],lens[i],m)!=b)return -1;x=next[i];}}
    if(count!=n)return -1;usz b=is_hash(a+3,q,m);long x=heads[b];while(x!=-1){usz i=x.usz();if(lens[i]==q){usz j=0;while(j<q&&a[off[i]+j]==a[3+j])j++;if(j==q)return i.long()+1;}x=next[i];}return 0;
}
