#include <cstddef>
#include <cstdint>
#define INVALID_RESULT (-1.0e300)
#define MAX_SAMPLES 16
extern "C" double gradient_boosting_regressor(const int64_t* v, std::size_t len) {
    if (!v || len < 8 || len > 36) return INVALID_RESULT;
    auto n64=v[0], rounds=v[1], rate_i=v[2], query_i=v[3];
    if(n64<2||n64>MAX_SAMPLES||rounds<1||rounds>12||rate_i<1||rate_i>1000000||len!=4+2*static_cast<std::size_t>(n64))return INVALID_RESULT;
    auto n=static_cast<std::size_t>(n64);double x[MAX_SAMPLES],y[MAX_SAMPLES],pred[MAX_SAMPLES],residual[MAX_SAMPLES];
    for(std::size_t i=0;i<n;i++){auto xi=v[4+i],yi=v[4+n+i];if(xi < -1000||xi>1000||yi < -1000000||yi>1000000||(i&&v[3+i]>=xi))return INVALID_RESULT;x[i]=static_cast<double>(xi);y[i]=static_cast<double>(yi)/1000.0;}
    if(query_i < -1000||query_i>1000)return INVALID_RESULT;
    double mean=0;for(std::size_t i=0;i<n;i++)mean+=y[i];mean/=static_cast<double>(n);for(std::size_t i=0;i<n;i++)pred[i]=mean;
    double qpred=mean,rate=static_cast<double>(rate_i)/1000000.0;
    for(int64_t r=0;r<rounds;r++){
      double sum=0;for(std::size_t i=0;i<n;i++){residual[i]=y[i]-pred[i];sum+=residual[i];}
      bool constant=true;for(std::size_t i=1;i<n;i++)if(residual[i]!=residual[0])constant=false;
      double best=1e300,left=0,right=0;std::size_t split=n;
      if(!constant)for(std::size_t s=0;s+1<n;s++){auto nl=s+1,nr=n-nl;double sl=0,sr=0;for(std::size_t i=0;i<nl;i++)sl+=residual[i];for(std::size_t i=nl;i<n;i++)sr+=residual[i];double lm=sl/nl,rm=sr/nr,err=0;for(std::size_t i=0;i<nl;i++){double d=residual[i]-lm;err+=d*d;}for(std::size_t i=nl;i<n;i++){double d=residual[i]-rm;err+=d*d;}if(err<best){best=err;split=s;left=lm;right=rm;}}
      if(split==n){double leaf=sum/n;for(std::size_t i=0;i<n;i++)pred[i]+=rate*leaf;qpred+=rate*leaf;}else{double t=(x[split]+x[split+1])/2;for(std::size_t i=0;i<n;i++)pred[i]+=rate*(x[i]<=t?left:right);qpred+=rate*(query_i<=t?left:right);}
    }return qpred;
}
