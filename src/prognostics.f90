!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Solve prognostic vorticity equation in spectral coordinates
! List of parameters from diagnostics.f90 that this function reads from:
!  * adv_[12]_sp:  the spectral advection terms for (anomalous?) pv
!  * q[12]_sp:     the (anomalous?) pv
!  * qyyflux_tt[12]: the total meridional pv flux convergence (eddy-->mean)
!  * ubar_tt[12]:   the zonal mean wind
! These are all ***transformed*** values; trigonometric in y, Fourier in x.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
module prognostics
contains
subroutine prog
  use global_variables
  implicit none
  integer :: i, j, i1, j1, n1, m1, ii, jj
  real    :: ell, rkk, kkk, filter

  ! Populate older positions with current position
  if(t.eq.tstart) then
    adv1_sp(:,:,2) = adv1_sp(:,:,3)
    adv1_sp(:,:,1) = adv1_sp(:,:,2)
    adv2_sp(:,:,2) = adv2_sp(:,:,3)
    adv2_sp(:,:,1) = adv2_sp(:,:,2)
    qyyflux1_tt(:,2) = qyyflux1_tt(:,3)
    qyyflux1_tt(:,1) = qyyflux1_tt(:,2)
    qyyflux2_tt(:,2) = qyyflux2_tt(:,3)
    qyyflux2_tt(:,1) = qyyflux2_tt(:,2)
  endif

  do j = 2,jtrunc
    !    ---- Prognostic zonal pv anomalies ----
    ell = el*float(j-1)
    do i = 2,itrunc
      rkk = rk*float(i-1)
      ! Get *hyperdiffusion*, *radiation*, and *friction* terms
      ! Note vorticity is del^2(psi)
      ! Note psi are *anomalous* relative to background shear, so want
      ! radiation to relax their *difference* to zero
      visc1_sp(i,j) = -damp*((rkk**2 + ell**2)**3)*q1_sp(i,j,1) ! hyperdiffusion
      visc2_sp(i,j) = -damp*((rkk**2 + ell**2)**3)*q2_sp(i,j,1)
      rad1_sp(i,j)  = -(psi2_sp(i,j) - psi1_sp(i,j))/((rd*rd)*tau_r) ! radiation
      rad2_sp(i,j)  = (psi2_sp(i,j) - psi1_sp(i,j))/((rd*rd)*tau_r)
      fric2_sp(i,j)  = (rkk**2 + ell**2)*psi2_sp(i,j)/tau_f ! friction (equals negative of the vorticity anomaly)
      ! fric2_sp(i,j) = fric2_sp(i,j)-q2_sp(i,j,3)/tau_2
      ! Apply *hyperdiffusion*, *radiation*, and *pv injection* in upper layer
      q1_sp(i,j,2) = q1_sp(i,j,1) &
        - dt*(23.*adv1_sp(i,j,3) - 16.*adv1_sp(i,j,2) + 5.*adv1_sp(i,j,1))/12. &
        + dt*visc1_sp(i,j) &
        + dt*force1_sp(i,j) &
        + dt*rad1_sp(i,j)
      ! Apply *hyperdiffusion*, *radiation*, and *friction* in lower layer
      q2_sp(i,j,2) = q2_sp(i,j,1) &
        - dt*(23.*adv2_sp(i,j,3) - 16.*adv2_sp(i,j,2) + 5.*adv2_sp(i,j,1))/12. &
        + dt*visc2_sp(i,j) &
        + dt*rad2_sp(i,j) &
        + dt*fric2_sp(i,j)
    enddo
    !    ---- Prognostic meridional derivative of zonal mean pv ----
    ! Iterate, apply *hyperdiffusion* and *radiation* in upper layer
    qybar1_tt(j,2) = qybar1_tt(j,1) &
      - dt*(23.*qyyflux1_tt(j,3) - 16.*qyyflux1_tt(j,2) + 5.*qyyflux1_tt(j,1))/12. &
      - dt*damp*(ell**6)*qybar1_tt(j,1) &
      - dt*(ubar1_tt(j) - ubar2_tt(j))/(rd*rd*tau_r)
    ! Iterate, apply *hyperdiffusion*, *radiation*, and *friction* in lower layer
    qybar2_tt(j,2) = qybar2_tt(j,1) &
      - dt*(23.*qyyflux2_tt(j,3) - 16.*qyyflux2_tt(j,2) + 5.*qyyflux2_tt(j,1))/12. &
      - dt*damp*(ell**6)*qybar2_tt(j,1) &
      + dt*(ubar1_tt(j) - ubar2_tt(j))/(rd*rd*tau_r) &
      - dt*(ell*ell*ubar2_tt(j))/tau_f
  enddo

  !    ---- Apply truncation ----
  ! Is this really necessary? Never read from those positions anyway.
  ! Didn't we already do this?
  ! And why are we only truncating mean data in y? What gives yo?
  ! Maybe small waves with small frequency in y can have big frequency in x, so
  ! don't want to truncate those?
  q1_sp(1,j,2) = zero
  q2_sp(1,j,2) = zero
  q1_sp(itrunc+1:idft,j,2) = zero
  q2_sp(itrunc+1:idft,j,2) = zero
  q1_sp(:,jtrunc+1:jmax,2) = zero
  q2_sp(:,jtrunc+1:jmax,2) = zero
  qybar1_tt(jtrunc+1:jmax,2) = 0.
  qybar2_tt(jtrunc+1:jmax,2) = 0.

  return
end subroutine
end module
