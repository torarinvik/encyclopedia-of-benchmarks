# Extended Kalman filter: bounded nonlinear trace

This contract represents the pinned Java `ExtendedKalmanFilter`'s vector-state prediction and nonlinear measurement update. It is distinct from the local scalar `kalman_filter` candidate: it evaluates transition and observation Jacobians at the current estimate and updates covariance in Joseph form.

Input is `[steps,x0_milli,y0_milli,p00_milli,p01_milli,p11_milli,q0_milli,q1_milli,r_milli,z0_milli,...]`. Every state, covariance, noise, and observation input is divided by 1000. The bounded 2-state process is `f(x,y)=(x+0.1*y,y+0.05*x^2)` with Jacobian `[[1,0.1],[0.1*x,1]]`; the scalar observation is `h(x,y)=0.05*x^2+y` with Jacobian `[0.1*x,1]`. Each observation performs one predict followed by one update. Covariance correction is `A P A' + K R K'`, where `A=I-KH`, matching the source's Joseph update. Output is the first coordinate of the final corrected state. Malformed inputs return `-1e300`.

The contract limits traces to 1–8 observations, initial state magnitudes to 2, covariance/noise values to bounded nonnegative domains, positive definite initial covariance, and finite-range observations. It compares deterministic numeric outputs with a 1e-12 absolute and relative tolerance.

Pinned source: [TheAlgorithms/Java `ExtendedKalmanFilter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/ExtendedKalmanFilter.java).
