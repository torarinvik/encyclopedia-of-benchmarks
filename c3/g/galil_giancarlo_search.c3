module galil_giancarlo_search;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT = 4227;
const usz TABLES = 130;

fn long gg_preprocess(long* pattern, usz m, long* order, long* next, long* shift) {
    long[TABLES] hmax=zeroed, kmin=zeroed, nohole_prefix=zeroed, rmin=zeroed;
    long i=1, k=1;
    while ((usz)k <= m) {
        while (pattern[i] == pattern[i-k]) i++;
        hmax[k]=i;
        long q=k+1;
        while (hmax[q-k]+k < i) { hmax[q]=hmax[q-k]+k; q++; }
        k=q;
        if (k == i+1) i=k;
    }
    for (i=(long)m; i>=1; i--) if ((usz)hmax[i] < m) kmin[hmax[i]]=i;
    long r=(long)m;
    for (i=(long)m-1; i>=0; i--) {
        if ((usz)hmax[i+1] == m) r=i+1;
        if (kmin[i] == 0) rmin[i]=r;
    }
    long split=-1;
    r=(long)m;
    for (i=0; (usz)i<m; i++) {
        if (kmin[i] == 0) order[--r]=i;
        else order[++split]=i;
    }
    long nd=split;
    for (i=0; i<=nd; i++) shift[i]=kmin[order[i]];
    for (i=nd+1; (usz)i<m; i++) shift[i]=rmin[order[i]];
    shift[m]=rmin[0];
    long count=0;
    for (i=0; (usz)i<m; i++) {
        nohole_prefix[i]=count;
        if (kmin[i]>0) count++;
    }
    for (i=0; i<=nd; i++) next[i]=nohole_prefix[order[i]-kmin[order[i]]];
    for (i=nd+1; (usz)i<m; i++) next[i]=nohole_prefix[(long)m-rmin[order[i]]];
    next[m]=nohole_prefix[(long)m-rmin[order[m-1]]];
    return nd;
}

fn long gg_search(long* text, usz n, long* pattern, usz m) {
    usz ell=0;
    while (ell+1<m && pattern[ell+1]==pattern[0]) ell++;
    long matches=0, sum=0, xor_sum=0;
    if (ell==m-1) {
        usz run=0;
        for (usz p=0;p<n;p++) {
            if (text[p]==pattern[0]) run++;
            else run=0;
            if (run>=m) { long start=(long)(p+1-m); matches++; sum+=start; xor_sum^=start; }
        }
        return (matches<<36)|(sum<<12)|xor_sum;
    }
    long[TABLES] order=zeroed, next=zeroed, shift=zeroed;
    long nd=gg_preprocess(pattern,m,&order[0],&next[0],&shift[0]);
    if (n<m) return 0;
    long i=0,j=0,last=-1;
    bool heavy=false;
    while ((usz)j<=n-m) {
        if (heavy && i==0) {
            long k=last-j+1;
            while ((usz)(j+k)<n && pattern[0]==text[j+k]) k++;
            if ((usz)k<=ell || (usz)(j+k)>=n || pattern[ell+1]!=text[j+k]) {
                i=0; j+=k+1; last=j-1;
            } else {
                i=1; last=j+k; j=last-(long)(ell+1);
            }
        } else {
            while ((usz)i<m && last<j+order[i] && pattern[order[i]]==text[j+order[i]]) i++;
            if ((usz)i>=m || last>=j+order[i]) { matches++; sum+=j; xor_sum^=j; i=(long)m; }
            if (i>nd) last=j+(long)m-1;
            j+=shift[i]; i=next[i];
        }
        heavy=j<=last;
    }
    return (matches<<36)|(sum<<12)|xor_sum;
}

fn long galil_giancarlo_search(long* input, usz length) @export("galil_giancarlo_search") {
    if (input==null || length<2 || length>MAX_INPUT) return -1;
    long n_value=input[0], m_value=input[1];
    if (n_value<0 || n_value>(long)MAX_TEXT || m_value<1 || m_value>(long)MAX_PATTERN) return -1;
    usz n=(usz)n_value,m=(usz)m_value;
    if (length!=2+n+m) return -1;
    long[MAX_TEXT] text=zeroed;
    long[TABLES] pattern=zeroed;
    for (usz i=0;i<n;i++) { if (input[2+i]<0 || input[2+i]>3) return -1; text[i]=input[2+i]; }
    for (usz i=0;i<m;i++) { long symbol=input[2+n+i]; if (symbol<0 || symbol>3) return -1; pattern[i]=symbol; }
    pattern[m]=4;
    return gg_search(&text[0],n,&pattern[0],m);
}
