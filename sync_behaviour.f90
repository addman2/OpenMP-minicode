!#######################################################################
!
! To run this minicode one has to pass:
! number of walkers NW
! number number of orbitals NORB
! number of basis NBAS
!
! like:
! echo $NW $NORB $NBAS | ./executable
!
!#######################################################################

program minicode
  use omp_lib
  implicit none
  !
  real(kind = 8), allocatable, dimension(:,:) :: David, Asterix  ! Small arrays
  real(kind = 8), allocatable, dimension(:,:) :: Goliath, Obelix ! Big arrays
  !
  real(kind = 8), parameter :: alpha = 1.0, beta = 0.0
  !
  integer :: SMALL, BIG
  integer :: rate, T_start_1, T_finish_1, T_start_2, T_finish_2
  !
  call system_clock(count_rate = rate)
  !
  read (*,*) SMALL, BIG
  !
  print *, "Testing Dgemm"
  print *, "SMALL", SMALL
  print *, "BIG", BIG
  !
  allocate(David(SMALL, SMALL))
  allocate(Asterix(SMALL, SMALL))
  allocate(Goliath(BIG, BIG))
  allocate(Obelix(BIG, BIG))
  !
  call random_number(David)
  call random_number(Asterix)
  call random_number(Goliath)
  call random_number(Obelix)
  !
  !#######################################################################
  !
  ! Offload first
  !
  !#######################################################################
  !
  !$omp target data map(to:David,Asterix,Goliath,Obelix)
  !
  print *, "Starting"
  !
  !$omp parallel num_threads(2) default(shared)
  if (omp_get_thread_num().eq.0) then
    call cublas_dgemm_offload("N","N", SMALL, SMALL, SMALL&
                             &,alpha, David, SMALL&
                             &,Asterix, SMALL&
                             &,beta,Asterix,SMALL)
    call system_clock(T_start_1)
    call cudasync
    call system_clock(T_finish_1)
    write (*,*) " Total time(small) ", (T_finish_1 - T_start_1) / real(rate)
  end if
  if (omp_get_thread_num().eq.1) then
    call cublas_dgemm_offload("N","N", BIG, BIG, BIG&
                             &,alpha, Goliath, BIG&
                             &,Obelix, BIG&
                             &,beta,Obelix,BIG)
    call system_clock(T_start_2)
    call cudasync
    call system_clock(T_finish_2)
    write (*,*) " Total time(big) ", (T_finish_2 - T_start_2) / real(rate)
  end if
  !
  !$omp barrier
  !$omp end parallel
  !$omp end target data
  !
  deallocate(David)
  deallocate(Goliath)
  deallocate(Asterix)
  deallocate(Obelix)
end program minicode
