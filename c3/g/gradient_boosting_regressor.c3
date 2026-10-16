module gradient_boosting_regressor;
const double INVALID_RESULT = -1.0e300;
const usz MAX_SAMPLES = 16;
fn double gradient_boosting_regressor(long* v, usz len) @export("gradient_boosting_regressor") {
    if (v == null || len < 8 || len > 36) return INVALID_RESULT;
    long n64=v[0]; long rounds=v[1]; long rate_i=v[2]; long query=v[3];
    if(n64<2||n64>16||rounds<1||rounds>12||rate_i<1||rate_i>1000000||len!=4+2*(usz)n64)return INVALID_RESULT;
    usz n=(usz)n64; double[MAX_SAMPLES] x; double[MAX_SAMPLES] y; double[MAX_SAMPLES] pred; double[MAX_SAMPLES] residual;
    for(usz i=0;i<n;i++){long xi=v[4+i]; long yi=v[4+n+i];if(xi< -1000||xi>1000||yi< -1000000||yi>1000000||(i>0&&v[3+i]>=xi))return INVALID_RESULT;x[i]=(double)xi;y[i]=(double)yi/1000.0;}
    if(query< -1000||query>1000)return INVALID_RESULT;
    double mean=0.0;for(usz i=0;i<n;i++)mean+=y[i];mean/=(double)n;for(usz i=0;i<n;i++)pred[i]=mean;double qpred=mean; double rate=(double)rate_i/1000000.0;
    for(long r=0;r<rounds;r++){double sum=0.0;for(usz i=0;i<n;i++){residual[i]=y[i]-pred[i];sum+=residual[i];}bool constant=true;for(usz i=1;i<n;i++)if(residual[i]!=residual[0])constant=false;
      double best=1.0e300; double left=0.0; double right=0.0; usz split=n;
      if(!constant)for(usz s=0;s+1<n;s++){usz nl=s+1; usz nr=n-nl;double sl=0.0; double sr=0.0;for(usz i=0;i<nl;i++)sl+=residual[i];for(usz i=nl;i<n;i++)sr+=residual[i];double lm=sl/(double)nl; double rm=sr/(double)nr; double err=0.0;for(usz i=0;i<nl;i++){double d=residual[i]-lm;err+=d*d;}for(usz i=nl;i<n;i++){double d=residual[i]-rm;err+=d*d;}if(err<best){best=err;split=s;left=lm;right=rm;}}
      if(split==n){double leaf=sum/(double)n;for(usz i=0;i<n;i++)pred[i]+=rate*leaf;qpred+=rate*leaf;}else{double t=(x[split]+x[split+1])/2.0;for(usz i=0;i<n;i++)pred[i]+=rate*(x[i]<=t?left:right);qpred+=rate*((double)query<=t?left:right);}
    }return qpred;
}
