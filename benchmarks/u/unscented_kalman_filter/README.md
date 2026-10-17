# Unscented Kalman filter: bounded nonlinear trace

This benchmark follows the pinned Java `UnscentedKalmanFilter` for a two-dimensional state and scalar measurement. Each observation performs one nonlinear prediction and one measurement update using sigma points. This is distinct from `extended_kalman_filter`, which propagates Jacobians and uses a Joseph covariance update.

Input is `[steps,x0_milli,y0_milli,p00_milli,p01_milli,p11_milli,q0_milli,q1_milli,r_milli,z0_milli,...]`. Values are divided by 1000. The transition is `f(x,y)=(x+0.1*y,y+0.05*x^2)` and the observation model is `h(x,y)=0.05*x^2+y`. The fixed parameters are alpha=1, beta=2, and kappa=0. For state dimension n=2, `lambda=alpha^2*(n+kappa)-n=0`, so the five sigma points use the center followed by plus and minus the two columns of the lower Cholesky factor of `2P`. Mean weights are `[0,1/4,1/4,1/4,1/4]`; covariance weights are `[2,1/4,1/4,1/4,1/4]`.

Prediction transforms all five points, computes the weighted state mean and covariance, adds diagonal process noise Q, then symmetrizes the covariance. The update transforms the predicted points through h, computes scalar innovation variance S and state/measurement cross-covariance, then applies `K=cross/S`, `state += K*(z-expected_z)`, and `P=symmetrize(P-K*S*K^T)`. Because the measurement is scalar, division by S is the 1-by-1 specialization of the source's `InverseOfMatrix.invert` dependency.

The input contract allows 1–8 observations; initial state coordinates are in [-1,1], diagonal covariance entries in [0.5,1], the off-diagonal covariance in [-0.1,0.1], process-noise diagonal entries in [0.01,0.05], measurement noise in [0.01,0.1], and observations in [-2,2]. These covariance bounds guarantee a positive-definite initial covariance. Malformed inputs return `-1e300`. The output is the first coordinate of the final state and is compared with 1e-12 absolute and relative tolerance.

Pinned source: [TheAlgorithms/Java `UnscentedKalmanFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/UnscentedKalmanFilter.java).
