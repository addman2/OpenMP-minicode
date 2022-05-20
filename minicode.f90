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
  real(kind = 8), allocatable, dimension(:,:,:) :: A
  real(kind = 8), allocatable, dimension(:,:) :: V, V_cublas
  !
  real(kind = 8), parameter :: alpha = 1.0, beta = 0.0
  real*8 :: max_error, difference
  !
  integer :: NW, NORB, NBAS, i, j, T_start, T_finish, offload_acc, &
           & T_offload_start, T_offload_finish, rate, walker_index, ngen
  !
  call system_clock(count_rate = rate)
  !
  read (*,*) NW, NORB, NBAS
  ngen = 1000
  offload_acc = 0
  !
  print *, "Testing Dgemv"
  print *, "NW", NW
  print *, "NORB", NORB
  print *, "NBAS", NBAS
  print *, "ngen", ngen
  !
  allocate(A(NORB,NBAS,NW))
  allocate(V(NORB,NW))
  allocate(V_cublas(NORB,NW))
  !
  call random_number(V)
  call random_number(A)
  !
  !#######################################################################
  !
  ! Offload first
  !
  !#######################################################################
  !
  !$omp target data map(to:A)
  !$omp target data map(alloc:V,V_cublas)
  !
  !#######################################################################
  !
  ! This allows nested openmp, easy!
  !
  !#######################################################################
  !
  call omp_set_nested(.TRUE.)
  !
  print *, "Starting"
  call system_clock(T_start)
  !
  do i = 1, ngen
    !
    ! Progress bar
    if (modulo(i, ngen/10).eq.0) then
      print *, i*100/ngen, "%"
    end if
    !
    !$omp parallel num_threads(NW) private(j,walker_index) default(shared)
    !
    !#######################################################################
    !
    ! The inner most OpenMP parallel region defines the results of functions:
    !
    ! omp_get_tread_num
    ! omp_get_num_threads
    ! etc ...
    !
    ! Therefore one has to store the walker index if needed for something
    !
    ! Also we do not need loop here
    !
    !#######################################################################
    !
    walker_index = omp_get_thread_num() + 1
    !
    !#######################################################################
    !
    ! This part simulates some operation on individual walkers
    !
    ! N.B. one can start a new parallel region with arbitrary num of threads
    !      ofcourse NORB is a stupid number it is better to put something
    !      hardware specific like:
    !
    !      NW * X = #CPUs
    !
    !#######################################################################
    !
    !$omp parallel do
    !# num_threads(NORB)
    do j = 1, NORB
      !print *, omp_get_thread_num()
      V(j,walker_index) = V(j,walker_index) + 0.0001
    end do
    !$omp end parallel do
    !
    !#######################################################################
    !
    ! Only one walker can operate the data offloading (first walker)
    ! To be super safe barriers everywhere to avoid reace conditions
    !
    !#######################################################################
    !
    !$omp barrier
    if (walker_index.eq.1) call system_clock(T_offload_start)
    !$omp target update to(V) if(walker_index.eq.1)
    call cublas_dgemv_offload("N",NORB,NBAS,alpha,A(:,:,walker_index),NORB,V(:,walker_index),1,beta,V_cublas(:,walker_index),1)
    CALL cudasync
    !$omp barrier
    !$omp target update to(V_cublas) if(walker_index.eq.1)
    if (walker_index.eq.1) call system_clock(T_offload_finish)
    if (walker_index.eq.1) offload_acc = offload_acc + T_offload_finish - T_offload_start
    !
    !$omp end parallel
  end do
  call system_clock(T_finish)
  !$omp end target data
  !$omp end target data
  !
  write (*,*) " Time spend in GPU", offload_acc / real(rate)
  write (*,*) " Total time ", (T_finish - T_start) / real(rate)
  !
  deallocate(A)
  deallocate(V)
  deallocate(V_cublas)
end program minicode
