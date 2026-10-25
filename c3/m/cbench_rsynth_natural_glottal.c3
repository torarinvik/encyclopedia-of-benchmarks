module cbench_rsynth_natural_glottal;

fn long cbench_rsynth_natural_glottal_sample(double* input, usz n, double* output, usz cap)
    @export("cbench_rsynth_natural_glottal_sample") {
    if(input==null||n==0||n>3)return -1;
    for(usz i=0;i<n;i++)if(input[i]!=input[i])return -1;
    if(n!=2||input[0]<40.0||input[0]>263.0||input[0]!=(double)(long)input[0]||input[1]<0.0||input[1]>299.0||input[1]!=(double)(long)input[1])return -1;
    long nopen=(long)input[0],index=(long)input[1];float result=0.0f;
    if(index<nopen){long b_int=1920000/(nopen*nopen);float b=(float)b_int;float product=(float)(b*(float)nopen);float a=(float)((double)product*0.333);float wave=0.0f;for(long i=0;i<=index;i++){a=a-b;wave=wave+a;}result=(float)((double)wave*0.028);}
    if(output==null||cap<1)return -2;output[0]=(double)result;return 1;
}
