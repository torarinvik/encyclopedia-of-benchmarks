import std/math

proc simple_pendulum_rk4*(values: ptr UncheckedArray[float64], length: csize_t,
    output: ptr UncheckedArray[float64], capacity: csize_t): int64 {.cdecl, exportc: "simple_pendulum_rk4".} =
  if values == nil or length != 5: return -1
  let minimums = [10000.0, 100000.0, -3141593.0, -100000000.0, 1.0]
  let maximums = [100000000.0, 20000000.0, 3141593.0, 100000000.0, 100000.0]
  for i in 0 ..< 5:
    if values[i] != values[i] or floor(values[i]) != values[i] or
        values[i] < minimums[i] or values[i] > maximums[i]: return -1

  let lengthM = values[0] / 1000000.0
  let gravity = values[1] / 1000000.0
  let theta = values[2] / 1000000.0
  let omega = values[3] / 1000000.0
  let dt = values[4] / 1000000.0
  let scale = gravity / lengthM

  let k1Theta = omega
  let k1Omega = -scale * sin(theta)
  let k2Theta = omega + 0.5 * dt * k1Omega
  let k2Omega = -scale * sin(theta + 0.5 * dt * k1Theta)
  let k3Theta = omega + 0.5 * dt * k2Omega
  let k3Omega = -scale * sin(theta + 0.5 * dt * k2Theta)
  let k4Theta = omega + dt * k3Omega
  let k4Omega = -scale * sin(theta + dt * k3Theta)
  let thetaNext = theta + dt / 6.0 * (k1Theta + 2.0 * k2Theta + 2.0 * k3Theta + k4Theta)
  let omegaNext = omega + dt / 6.0 * (k1Omega + 2.0 * k2Omega + 2.0 * k3Omega + k4Omega)

  if output == nil or capacity < 2: return -2
  output[0] = thetaNext
  output[1] = omegaNext
  2
