module hierholzer_algorithm;
fn long hierholzer_algorithm(long* a, usz length) @export("hierholzer_algorithm") {
    if(a==null||length<2)return -1;long nn=a[0],mm=a[1];
    if(nn<0||nn>8||mm<0||mm>256||(nn==0&&mm!=0)||length!=2+2*(usz)mm)return -1;
    usz n=(usz)nn,m=(usz)mm;long[8][512] adj;usz[8] deg;
    for(usz e=0;e<m;e++){long u=a[2+2*e],v=a[3+2*e];if(u<0||u>=nn||v<0||v>=nn)return -1;adj[(usz)u][deg[(usz)u]++]=v;adj[(usz)v][deg[(usz)v]++]=u;}
    long[259] rec;usz rn=0;bool valid=true;long[8] seen;long[8] q;usz qh=0,qt=0;
    if(m==0){rec[rn++]=1;rec[rn++]=n>0?1:0;if(n>0)rec[rn++]=0;}
    else {
        for(usz i=0;i<n;i++)if(deg[i]%2!=0)valid=false;
        usz start=0;while(start<n&&deg[start]==0)start++;
        if(valid){seen[start]=1;q[qt++]=(long)start;while(qh<qt){usz x=(usz)q[qh++];for(usz j=0;j<deg[x];j++){usz y=(usz)adj[x][j];if(!seen[y]){seen[y]=1;q[qt++]=(long)y;}}}for(usz i=0;i<n;i++)if(deg[i]>0&&!seen[i])valid=false;}
        if(valid){long[8][512] work;usz[8] wd;for(usz i=0;i<n;i++){wd[i]=deg[i];for(usz j=0;j<deg[i];j++)work[i][j]=adj[i][j];}
            long[258] stack;long[258] circuit;usz sp=0,cp=0;stack[sp++]=(long)start;
            while(sp>0){usz v=(usz)stack[sp-1];if(wd[v]>0){usz w=(usz)work[v][0];for(usz j=1;j<wd[v];j++)work[v][j-1]=work[v][j];wd[v]--;usz k=0;while(k<wd[w]&&work[w][k]!=(long)v)k++;if(k==wd[w]){valid=false;break;}for(usz j=k+1;j<wd[w];j++)work[w][j-1]=work[w][j];wd[w]--;stack[sp++]=(long)w;}else circuit[cp++]=stack[--sp];}
            if(valid){rec[rn++]=1;rec[rn++]=(long)cp;while(cp>0)rec[rn++]=circuit[--cp];}
        }
        if(!valid){rn=0;rec[rn++]=0;rec[rn++]=0;}
    }
    ulong h=14695981039346656037;for(usz i=0;i<rn;i++){ulong z=(ulong)rec[i];for(usz b=0;b<8;b++){h=(h^(z&255))*1099511628211;z>>=8;}}
    return (long)(h&0x7fffffffffffffff);
}
