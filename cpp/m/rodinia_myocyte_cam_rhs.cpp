/* Clean-room bounded port of Rodinia Myocyte's kernel_cam RHS; see package LICENSE.txt. */
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kInputLength = 22;
float decode(std::int64_t raw) { return static_cast<float>(raw) / 1'000'000.0f; }
float addf(float a, float b) { return a + b; }
float subf(float a, float b) { return a - b; }
float mulf(float a, float b) { return a * b; }
float divf(float a, float b) { return a / b; }
}

extern "C" double rodinia_myocyte_cam_rhs(const std::int64_t *input, std::size_t length) noexcept {
    constexpr double invalid = -1.0e300;
    if (input == nullptr || length != kInputLength) return invalid;
    if (input[0] < 0 || input[0] > 100'000'000 || input[1] < 100'000'000 || input[1] > 200'000'000 ||
        input[2] < 500'000 || input[2] > 5'000'000) return invalid;
    for (std::size_t i = 3; i < kInputLength; ++i) if (input[i] < 0 || input[i] > 10'000'000) return invalid;

    const float Ca=decode(input[0]), K=decode(input[1]), Mg=decode(input[2]);
    const float Btot=decode(input[3]), CaMKIItot=decode(input[4]), CaNtot=decode(input[5]), PP1tot=decode(input[6]);
    float s[15]; for (std::size_t i=0;i<15;++i) s[i]=decode(input[7+i]);
    const float CaM=s[0], Ca2CaM=s[1], Ca4CaM=s[2], CaMB=s[3], Ca2CaMB=s[4], Ca4CaMB=s[5];
    const float Pb2=s[6], Pb=s[7], Pt=s[8], Pt2=s[9], Pa=s[10];
    const float Ca4CaN=s[11], CaMCa4CaN=s[12], Ca2CaMCa4CaN=s[13], Ca4CaMCa4CaN=s[14];

    float Kd02, Kd24;
    if (Mg <= 1.0f) {
        Kd02=static_cast<float>(0.0025*(1.0+static_cast<double>(K)/0.94-static_cast<double>(Mg)/0.012)*(1.0+static_cast<double>(K)/8.1+static_cast<double>(Mg)/0.022));
        Kd24=static_cast<float>(0.128*(1.0+static_cast<double>(K)/0.64+static_cast<double>(Mg)/0.0014)*(1.0+static_cast<double>(K)/13.0-static_cast<double>(Mg)/0.153));
    } else {
        Kd02=static_cast<float>(0.0025*(1.0+static_cast<double>(K)/0.94-1.0/0.012+(static_cast<double>(Mg)-1.0)/0.060)*(1.0+static_cast<double>(K)/8.1+1.0/0.022+(static_cast<double>(Mg)-1.0)/0.068));
        Kd24=static_cast<float>(0.128*(1.0+static_cast<double>(K)/0.64+1.0/0.0014+(static_cast<double>(Mg)-1.0)/0.005)*(1.0+static_cast<double>(K)/13.0-1.0/0.153+(static_cast<double>(Mg)-1.0)/0.150));
    }
    if (!(Kd02>0.0f) || !(Kd24>0.0f) || !std::isfinite(Kd02) || !std::isfinite(Kd24)) return invalid;

    const float k20=10.0f, k02=divf(k20,Kd02), k42=500.0f, k24=divf(k42,Kd24);
    const float k0Boff=0.0014f, k0Bon=static_cast<float>(static_cast<double>(k0Boff)/0.2);
    const float k2Boff=divf(k0Boff,100.0f), k2Bon=k0Bon, k4Boff=k2Boff, k4Bon=k0Bon;
    const float k20B=divf(k20,100.0f), k02B=k02, k42B=k42, k24B=k24;
    const float kbi=2.2f, kib=static_cast<float>(static_cast<double>(kbi)/33.5e-3), kpp1=1.72f, Kmpp1=11.5f;
    const float kib2=kib, kb2i=mulf(kib2,5.0f), kb24=k24;
    const float kb42=static_cast<float>(static_cast<double>(k42)*33.5e-3/5.0), kta=divf(kbi,1000.0f), kat=kib;
    const float kt42=static_cast<float>(static_cast<double>(k42)*33.5e-6/5.0), kt24=k24, kat2=kib, kt2a=mulf(kib,5.0f);
    const float kcanCaoff=1.0f, kcanCaon=static_cast<float>(static_cast<double>(kcanCaoff)/0.5);
    const float kcanCaM4on=46.0f, kcanCaM4off=0.0013f, kcanCaM2on=kcanCaM4on;
    const float kcanCaM2off=mulf(2508.0f,kcanCaM4off), kcanCaM0on=kcanCaM4on;
    const float kcanCaM0off=mulf(165.0f,kcanCaM2off), k02can=k02;
    const float k20can=divf(k20,165.0f), k24can=k24, k42can=divf(k20,2508.0f);

    const double ca2=static_cast<double>(Ca)*static_cast<double>(Ca);
    const float rcn02=static_cast<float>(static_cast<double>(k02)*ca2*CaM-static_cast<double>(k20)*Ca2CaM);
    const float rcn24=static_cast<float>(static_cast<double>(k24)*ca2*Ca2CaM-static_cast<double>(k42)*Ca4CaM);
    const float B=subf(subf(subf(Btot,CaMB),Ca2CaMB),Ca4CaMB);
    const float rcn02B=static_cast<float>(static_cast<double>(k02B)*ca2*CaMB-static_cast<double>(k20B)*Ca2CaMB);
    const float rcn24B=static_cast<float>(static_cast<double>(k24B)*ca2*Ca2CaMB-static_cast<double>(k42B)*Ca4CaMB);
    const float rcn0B=subf(mulf(mulf(k0Bon,CaM),B),mulf(k0Boff,CaMB));
    const float rcn2B=subf(mulf(mulf(k2Bon,Ca2CaM),B),mulf(k2Boff,Ca2CaMB));
    const float rcn4B=subf(mulf(mulf(k4Bon,Ca4CaM),B),mulf(k4Boff,Ca4CaMB));

    const float Ca2CaN=subf(subf(subf(subf(CaNtot,Ca4CaN),CaMCa4CaN),Ca2CaMCa4CaN),Ca4CaMCa4CaN);
    const float rcnCa4CaN=static_cast<float>(static_cast<double>(kcanCaon)*ca2*Ca2CaN-static_cast<double>(kcanCaoff)*Ca4CaN);
    const float rcn02CaN=static_cast<float>(static_cast<double>(k02can)*ca2*CaMCa4CaN-static_cast<double>(k20can)*Ca2CaMCa4CaN);
    const float rcn24CaN=static_cast<float>(static_cast<double>(k24can)*ca2*Ca2CaMCa4CaN-static_cast<double>(k42can)*Ca4CaMCa4CaN);
    const float rcn0CaN=subf(mulf(mulf(kcanCaM0on,CaM),Ca4CaN),mulf(kcanCaM0off,CaMCa4CaN));
    const float rcn2CaN=subf(mulf(mulf(kcanCaM2on,Ca2CaM),Ca4CaN),mulf(kcanCaM2off,Ca2CaMCa4CaN));
    const float rcn4CaN=subf(mulf(mulf(kcanCaM4on,Ca4CaM),Ca4CaN),mulf(kcanCaM4off,Ca4CaMCa4CaN));

    const float Pix=subf(subf(subf(subf(subf(1.0f,Pb2),Pb),Pt),Pt2),Pa);
    const float rcnCKib2=subf(mulf(mulf(kib2,Ca2CaM),Pix),mulf(kb2i,Pb2));
    const float rcnCKb2b=static_cast<float>(static_cast<double>(kb24)*ca2*Pb2-static_cast<double>(kb42)*Pb);
    const float rcnCKib=subf(mulf(mulf(kib,Ca4CaM),Pix),mulf(kbi,Pb));
    const float T=addf(addf(addf(Pb,Pt),Pt2),Pa); const double Td=T;
    const float kbt=static_cast<float>(0.055*Td+0.0074*Td*Td+0.015*Td*Td*Td);
    const float rcnCKbt=subf(mulf(kbt,Pb),divf(mulf(mulf(kpp1,PP1tot),Pt),addf(Kmpp1,mulf(CaMKIItot,Pt))));
    const float rcnCKtt2=subf(mulf(kt42,Pt),static_cast<float>(static_cast<double>(kt24)*ca2*Pt2));
    const float rcnCKta=subf(mulf(kta,Pt),mulf(mulf(kat,Ca4CaM),Pa));
    const float rcnCKt2a=subf(mulf(kt2a,Pt2),mulf(mulf(kat2,Ca2CaM),Pa));
    const float rcnCKt2b2=divf(mulf(mulf(kpp1,PP1tot),Pt2),addf(Kmpp1,mulf(CaMKIItot,Pt2)));
    const float rcnCKai=divf(mulf(mulf(kpp1,PP1tot),Pa),addf(Kmpp1,mulf(CaMKIItot,Pa)));

    float d[16];
    d[0]=static_cast<float>(1e-3*static_cast<double>(subf(subf(-rcn02,rcn0B),rcn0CaN)));
    float term=addf(subf(subf(subf(rcn02,rcn24),rcn2B),rcn2CaN),mulf(CaMKIItot,addf(-rcnCKib2,rcnCKt2a)));
    d[1]=static_cast<float>(1e-3*static_cast<double>(term));
    term=addf(subf(subf(rcn24,rcn4B),rcn4CaN),mulf(CaMKIItot,addf(-rcnCKib,rcnCKta)));
    d[2]=static_cast<float>(1e-3*static_cast<double>(term));
    d[3]=static_cast<float>(1e-3*static_cast<double>(subf(rcn0B,rcn02B)));
    d[4]=static_cast<float>(1e-3*static_cast<double>(subf(addf(rcn02B,rcn2B),rcn24B)));
    d[5]=static_cast<float>(1e-3*static_cast<double>(addf(rcn24B,rcn4B)));
    d[6]=static_cast<float>(1e-3*static_cast<double>(addf(subf(rcnCKib2,rcnCKb2b),rcnCKt2b2)));
    d[7]=static_cast<float>(1e-3*static_cast<double>(subf(addf(rcnCKib,rcnCKb2b),rcnCKbt)));
    d[8]=static_cast<float>(1e-3*static_cast<double>(subf(subf(rcnCKbt,rcnCKta),rcnCKtt2)));
    d[9]=static_cast<float>(1e-3*static_cast<double>(subf(subf(rcnCKtt2,rcnCKt2a),rcnCKt2b2)));
    d[10]=static_cast<float>(1e-3*static_cast<double>(subf(addf(rcnCKta,rcnCKt2a),rcnCKai)));
    d[11]=static_cast<float>(1e-3*static_cast<double>(subf(subf(subf(rcnCa4CaN,rcn0CaN),rcn2CaN),rcn4CaN)));
    d[12]=static_cast<float>(1e-3*static_cast<double>(subf(rcn0CaN,rcn02CaN)));
    d[13]=static_cast<float>(1e-3*static_cast<double>(subf(addf(rcn2CaN,rcn02CaN),rcn24CaN)));
    d[14]=static_cast<float>(1e-3*static_cast<double>(addf(rcn4CaN,rcn24CaN)));
    float com_sum=addf(rcn02,rcn24); com_sum=addf(com_sum,rcn02B); com_sum=addf(com_sum,rcn24B);
    com_sum=addf(com_sum,rcnCa4CaN); com_sum=addf(com_sum,rcn02CaN); com_sum=addf(com_sum,rcn24CaN);
    d[15]=static_cast<float>(1e-3*static_cast<double>(subf(mulf(mulf(2.0f,CaMKIItot),subf(rcnCKtt2,rcnCKb2b)),mulf(2.0f,com_sum))));
    double checksum=0.0;
    for (std::size_t i=0;i<16;++i) { if (!std::isfinite(d[i])) d[i]=0.0001f; checksum += static_cast<double>(i+1)*static_cast<double>(d[i]); }
    return checksum;
}
