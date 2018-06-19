!****** Nonlinear 2 layer baroclinic instability on the beta-plane.  Periodic in x and rigid walls at north and south *****   
program main
  ! ****** Modules and stuff ****  
  use MKL_DFTI
  use GLOBAL_VARIABLES
  use INITIAL
  use FORWARD
  use EXEC
  use IO
  use INVERT
  type(DFTI_DESCRIPTOR), POINTER :: HX,HY
  integer :: L(1)
  L(1) = imx
  ! implicit none ! don't comment this out you monster

  ! ****** Initialize fields ****  
  call initial1      ! (initial.f90)
  Status = DftiCreateDescriptor( HX, DFTI_DOUBLE, &
    DFTI_REAL, 1, L)
  Status = DftiSetValue(HX, DFTI_PLACEMENT, DFTI_NOT_INPLACE)
  Status = DftiCommitDescriptor( HX )
  Status = DftiCreateDescriptor( HY, DFTI_DOUBLE, &
    DFTI_REAL, 1, L)
  Status = DftiSetValue(HY, DFTI_PLACEMENT, DFTI_NOT_INPLACE)
  Status = DftiCommitDescriptor( HY )

  ! ****** Integration *****
  do t = tstart, tend, dt ! note that loop is normally end-inclusive
    ! Invert data from previous timestep, and print diagnostics
    call invert1(HX,HY)                             ! (invert.f90) invert streamfunction from vorticity
    write(6,677) float(t)/(3600.*24.), energy2, cfl
    677 format("days = ",1f6.3," eke = ",1p1e13.5,cfl) ! 1p ensures non-zero digit to left of decimal
    if((mod(t,td).eq.0).and.(t.ge.tds)) call dataio ! (io.f90) save data
    ! Iterate and evaluate prognostic data
    ! call energy1                              ! (energy.f90) eddy energy calculation
    call prog                                       ! (exec.f90) eddy prognostic equation
    call forward1                                   ! (forward.f90) time forwarding
  enddo
  write(6,*) 'Final Day = ', float(t)/(3600.*24.)
  close(11)

  Status = DftiFreeDescriptor( HX )
  Status = DftiFreeDescriptor( HY )

  stop
end program
