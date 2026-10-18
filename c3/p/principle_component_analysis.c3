module principle_component_analysis;

extern fn double sqrt(double value);

const usz MAX_OUTPUT=38;
const double JACOBI_TOLERANCE=1e-14;
const double MIN_EIGEN_GAP=1e-8;

fn bool finite_value(double x) { return x==x && x<1e300 && x> -1e300; }

fn bool diagonalize(double* a, double* vectors, usz n, double* values) {
    for(usz i=0;i<n;i++) for(usz j=0;j<n;j++) vectors[i*4+j]=i==j?1.0:0.0;
    bool converged=false;
    for(usz sweep=0;sweep<=64;sweep++) {
        double largest=0.0;
        for(usz p=0;p<n;p++) for(usz q=p+1;q<n;q++) {
            double x=a[p*4+q]; if(x<0.0)x= -x; if(x>largest)largest=x;
        }
        if(largest<=JACOBI_TOLERANCE){converged=true;break;}
        if(sweep==64)break;
        for(usz p=0;p<n;p++) for(usz q=p+1;q<n;q++) {
            double apq=a[p*4+q], abs_apq=apq; if(abs_apq<0.0)abs_apq= -abs_apq;
            if(abs_apq<=JACOBI_TOLERANCE)continue;
            double tau=(a[q*4+q]-a[p*4+p])/(2.0*apq);
            double abs_tau=tau; if(abs_tau<0.0)abs_tau= -abs_tau;
            double sign=tau>=0.0?1.0:-1.0;
            double t=sign/(abs_tau+sqrt(1.0+tau*tau));
            double c=1.0/sqrt(1.0+t*t), s=t*c;
            double app=a[p*4+p], aqq=a[q*4+q];
            a[p*4+p]=app-t*apq; a[q*4+q]=aqq+t*apq;
            a[p*4+q]=0.0; a[q*4+p]=0.0;
            for(usz r=0;r<n;r++) {
                if(r!=p && r!=q) {
                    double arp=a[r*4+p], arq=a[r*4+q];
                    a[r*4+p]=c*arp-s*arq; a[p*4+r]=a[r*4+p];
                    a[r*4+q]=s*arp+c*arq; a[q*4+r]=a[r*4+q];
                }
                double vrp=vectors[r*4+p], vrq=vectors[r*4+q];
                vectors[r*4+p]=c*vrp-s*vrq; vectors[r*4+q]=s*vrp+c*vrq;
            }
        }
    }
    if(!converged)return false;
    for(usz i=0;i<n;i++)values[i]=a[i*4+i];
    for(usz i=0;i<n;i++)for(usz j=i+1;j<n;j++) if(values[j]>values[i]) {
        double temp=values[i];values[i]=values[j];values[j]=temp;
        for(usz r=0;r<n;r++){temp=vectors[r*4+i];vectors[r*4+i]=vectors[r*4+j];vectors[r*4+j]=temp;}
    }
    return true;
}

fn long principle_component_analysis(double* input, usz input_length,
                                     double* output, usz output_capacity) @export("principle_component_analysis") {
    if(input==null || input_length<3 || input_length>35)return -1L;
    for(usz i=0;i<input_length;i++)if(!finite_value(input[i]))return -1L;
    double nv=input[0], fv=input[1], cv=input[2];
    if(nv<3.0 || nv>8.0 || (double)(long)nv!=nv || fv<2.0 || fv>4.0 || (double)(long)fv!=fv || cv<1.0 || cv>4.0 || (double)(long)cv!=cv)return -1L;
    usz samples=(usz)(long)nv, features=(usz)(long)fv, components=(usz)(long)cv;
    if(samples<=features || components>features || input_length!=3+samples*features)return -1L;
    double[32] rows=zeroed; double[4] means=zeroed;
    for(usz r=0;r<samples;r++)for(usz c=0;c<features;c++) {
        double x=input[3+r*features+c];
        if((double)(long)x!=x || x< -9.0 || x>9.0)return -1L;
        rows[r*4+c]=x;means[c]+=x;if(!finite_value(means[c]))return -1L;
    }
    for(usz c=0;c<features;c++)means[c]/=(double)samples;
    double[4] variances=zeroed;
    for(usz r=0;r<samples;r++)for(usz c=0;c<features;c++){double d=rows[r*4+c]-means[c];variances[c]+=d*d;}
    double[4] scales=zeroed;
    for(usz c=0;c<features;c++){variances[c]/=(double)samples;if(!(variances[c]>0.0)||!finite_value(variances[c]))return -1L;scales[c]=sqrt(variances[c]);}
    double[32] z=zeroed;double[4] pca_means=zeroed;
    for(usz r=0;r<samples;r++)for(usz c=0;c<features;c++){z[r*4+c]=(rows[r*4+c]-means[c])/scales[c];pca_means[c]+=z[r*4+c];}
    for(usz c=0;c<features;c++)pca_means[c]/=(double)samples;
    double[32] centered=zeroed;
    for(usz r=0;r<samples;r++)for(usz c=0;c<features;c++)centered[r*4+c]=z[r*4+c]-pca_means[c];
    double[16] covariance=zeroed;
    for(usz i=0;i<features;i++)for(usz j=i;j<features;j++){
        double sum=0.0;for(usz r=0;r<samples;r++)sum+=centered[r*4+i]*centered[r*4+j];
        covariance[i*4+j]=sum/(double)(samples-1);covariance[j*4+i]=covariance[i*4+j];
    }
    double[16] vectors=zeroed;double[4] eigenvalues=zeroed;
    if(!diagonalize(&covariance[0],&vectors[0],features,&eigenvalues[0]))return -1L;
    for(usz i=0;i<features;i++){if(!(eigenvalues[i]>0.0)||!finite_value(eigenvalues[i])||(i+1<features&&eigenvalues[i]-eigenvalues[i+1]<=MIN_EIGEN_GAP))return -1L;}
    double total=0.0;for(usz i=0;i<features;i++)total+=eigenvalues[i];if(!(total>0.0)||!finite_value(total))return -1L;
    double[32] scores=zeroed;
    for(usz k=0;k<components;k++){
        for(usz r=0;r<samples;r++)for(usz c=0;c<features;c++)scores[k*8+r]+=centered[r*4+c]*vectors[c*4+k];
        usz pivot=0;for(usz r=1;r<samples;r++){double x=scores[k*8+r],y=scores[k*8+pivot];if(x<0.0)x= -x;if(y<0.0)y= -y;if(x>y)pivot=r;}
        if(scores[k*8+pivot]<0.0)for(usz r=0;r<samples;r++)scores[k*8+r]= -scores[k*8+r];
    }
    double[MAX_OUTPUT] staged=zeroed;staged[0]=(double)samples;staged[1]=(double)components;usz pos=2;
    for(usz r=0;r<samples;r++)for(usz k=0;k<components;k++)staged[pos++]=scores[k*8+r];
    for(usz k=0;k<components;k++)staged[pos++]=eigenvalues[k]/total;
    for(usz i=0;i<pos;i++)if(!finite_value(staged[i]))return -1L;
    if(output==null||output_capacity<pos)return -2L;
    for(usz i=0;i<pos;i++)output[i]=staged[i];
    return (long)pos;
}
