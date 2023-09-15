module problem_options
    use aptofem_kernel

    save

    real(db)          :: interior_penalty_parameter
    integer           :: no_uniform_refinements_cavity, no_uniform_refinements_everywhere, no_uniform_refinements_inlet
    logical           :: velocity_ss, velocity_ic_from_ss, transport_ic_from_ss, compute_transport, moving_mesh
    real(db)          :: final_local_time, central_cavity_width, central_cavity_height, central_cavity_transition, pipe_transition
    integer           :: no_time_steps
    integer           :: no_placentones
    character(len=20) :: geometry_name, assembly_name
    logical           :: compute_ss_flag

    real(db), dimension(:, :), allocatable :: vessel_locations

    contains
    subroutine get_user_data(section_name, aptofem_stored_keys)
        implicit none

        character(len=*), intent(in) :: section_name
        type(aptofem_keys), pointer  :: aptofem_stored_keys

        integer :: ierr, i
        character(len=1) :: temp_integer

        call get_aptofem_key_definition('interior_penalty_parameter',        interior_penalty_parameter,        section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('no_uniform_refinements_cavity',     no_uniform_refinements_cavity,     section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('no_uniform_refinements_inlet',      no_uniform_refinements_inlet,      section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('no_uniform_refinements_everywhere', no_uniform_refinements_everywhere, section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('velocity_ss',                       velocity_ss,                       section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('velocity_ic_from_ss',               velocity_ic_from_ss,               section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('transport_ic_from_ss',              transport_ic_from_ss,              section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('dirk_final_time',                   final_local_time,                  'solver_velocity', &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('dirk_number_of_timesteps',          no_time_steps,                     'solver_velocity', &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('compute_transport',                 compute_transport,                 section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('central_cavity_width',              central_cavity_width,              section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('central_cavity_height',             central_cavity_height,             section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('central_cavity_transition',         central_cavity_transition,         section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('pipe_transition',                   pipe_transition,                   section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('no_placentones',                    no_placentones,                    section_name, &
            aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('moving_mesh',                       moving_mesh,                       section_name, &
            aptofem_stored_keys, ierr)

        if (no_placentones /= 1 .and. no_placentones /= 6 .and. no_placentones /= 7) then
            print *, "Error in get_user_data. no_placentones must be 1 or 6 or 7. Stopping."
            stop 1
        end if

        allocate(vessel_locations(7, 3))
        do i = 1, 7
            write(temp_integer, '(I1)') i

            call get_aptofem_key_definition('vein_location_'   // temp_integer // '1', vessel_locations(i, 1), section_name, &
                aptofem_stored_keys, ierr)
            call get_aptofem_key_definition('artery_location_' // temp_integer,        vessel_locations(i, 2), section_name, &
                aptofem_stored_keys, ierr)
            call get_aptofem_key_definition('vein_location_'   // temp_integer // '2', vessel_locations(i, 3), section_name, &
                aptofem_stored_keys, ierr)
        end do

        compute_ss_flag = .true.
    end subroutine

    subroutine finalise_user_data()
        implicit none

        deallocate(vessel_locations)
    end subroutine

    function smooth_tanh_function(x, steepness, x0, x2)
        use param

        implicit none

        real(db)             :: smooth_tanh_function
        real(db), intent(in) :: x, steepness, x0, x2

        real(db) :: x1

        x1 = (x0 + x2)/2

        if (x <= x0) then
            smooth_tanh_function = 0.0_db
        else if (x0 < x .and. x < x2) then
            smooth_tanh_function = &
                (tanh(steepness*(x - x1)/(x2 - x1))/tanh(steepness) + 1)/2
        else if (x2 <= x) then
            smooth_tanh_function = 1.0_db
        else
            print *, "Error in smooth_tanh_function. Missed case. Stopping."
            print *, "x0 = ", x0
            print *, "x1 = ", x1
            print *, "x2 = ", x2
            print *, "x = ", x
            print *, "steepness = ", steepness
            stop 1
        end if
    end function

end module