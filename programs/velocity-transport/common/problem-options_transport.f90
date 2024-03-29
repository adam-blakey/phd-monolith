module problem_options_transport
    use aptofem_kernel
    use solution_storage_velocity

    save

    real(db) :: transport_diffusion_coefficient, transport_convection_coefficient, transport_reaction_coefficient, &
        transport_time_coefficient, transport_forcing_coefficient

contains
    subroutine get_user_data_transport(section_name, aptofem_stored_keys)
        implicit none

        character(len=*), intent(in) :: section_name
        type(aptofem_keys), pointer  :: aptofem_stored_keys

        integer :: ierr

        call get_aptofem_key_definition('transport_diffusion_coefficient', &
            transport_diffusion_coefficient, section_name, aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('transport_convection_coefficient', &
            transport_convection_coefficient, section_name, aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('transport_reaction_coefficient', &
            transport_reaction_coefficient,  section_name, aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('transport_time_coefficient', &
            transport_time_coefficient, section_name, aptofem_stored_keys, ierr)
        call get_aptofem_key_definition('transport_forcing_coefficient', &
            transport_forcing_coefficient, section_name, aptofem_stored_keys, ierr)

    end subroutine

    subroutine project_uptake(u, global_point, problem_dim, no_vars, boundary_no, t, element_region_id)
        implicit none

        real(db), dimension(no_vars), intent(out)    :: u
        real(db), dimension(problem_dim), intent(in) :: global_point
        integer, intent(in)                          :: problem_dim
        integer, intent(in)                          :: no_vars
        integer, intent(in)                          :: boundary_no
        real(db), intent(in)                         :: t
        integer, intent(in)                          :: element_region_id

        u = calculate_transport_reaction_coefficient(global_point, problem_dim, element_region_id)
    end subroutine

    subroutine calculate_convective_velocity(velocity, global_point, problem_dim, element_no, mesh_data)
        use param
        use mesh_facets

        implicit none

        real(db), dimension(problem_dim), intent(out) :: velocity
        real(db), dimension(problem_dim), intent(in)  :: global_point
        integer, intent(in)                           :: problem_dim
        integer, intent(in)                           :: element_no
        type(mesh), intent(in)                        :: mesh_data

        real(db), dimension(problem_dim+1) :: sol

        call compute_uh_glob_pt(sol, problem_dim+1, element_no, global_point, problem_dim, &
            mesh_data, solution_velocity)
        velocity(1:problem_dim) = sol(1:problem_dim)
    end subroutine

    subroutine calculate_convective_velocity_0_1(velocity, velocity_1, global_point, problem_dim, element_no, mesh_data)
        use param
        use mesh_facets

        implicit none

        real(db), dimension(problem_dim), intent(out)              :: velocity
        real(db), dimension(problem_dim, problem_dim), intent(out) :: velocity_1
        real(db), dimension(problem_dim), intent(in)               :: global_point
        integer, intent(in)                                        :: problem_dim
        integer, intent(in)                                        :: element_no
        type(mesh), intent(in)                                     :: mesh_data

        real(db), dimension(problem_dim+1)                :: sol
        real(db), dimension(problem_dim+1, problem_dim+1) :: sol_1

        call compute_uh_gradient_uh_glob_pt(sol, sol_1, problem_dim+1, element_no, global_point, problem_dim, &
            mesh_data, solution_velocity)
        velocity  (1:problem_dim)                = sol  (1:problem_dim)
        velocity_1(1:problem_dim, 1:problem_dim) = sol_1(1:problem_dim, 1:problem_dim)
    end subroutine

    function calculate_transport_diffusion_coefficient(global_point, problem_dim, element_region_id)
        use param

        real(db)                                     :: calculate_transport_diffusion_coefficient
        integer, intent(in)                          :: problem_dim
        real(db), dimension(problem_dim), intent(in) :: global_point
        integer, intent(in)                          :: element_region_id

        calculate_transport_diffusion_coefficient = transport_diffusion_coefficient
    end function

    function calculate_transport_convection_coefficient(global_point, problem_dim, element_region_id)
        use param

        real(db)                                     :: calculate_transport_convection_coefficient
        integer, intent(in)                          :: problem_dim
        real(db), dimension(problem_dim), intent(in) :: global_point
        integer, intent(in)                          :: element_region_id

        calculate_transport_convection_coefficient = transport_convection_coefficient
    end function

    function calculate_transport_reaction_coefficient(global_point, problem_dim, element_region_id)
        use param
        use problem_options
        use problem_options_geometry

        implicit none

        real(db)                                     :: calculate_transport_reaction_coefficient
        integer, intent(in)                          :: problem_dim
        real(db), dimension(problem_dim), intent(in) :: global_point
        integer, intent(in)                          :: element_region_id

        real(db)               :: steepness
        real(db), dimension(2) :: translated_point
        integer                :: placentone_no

        steepness = 0.999_db

        if (400 <= element_region_id .and. element_region_id <= 599) then
            if (trim(geometry_name) == 'placentone') then
                translated_point = translate_placentone_to_placentone_point(problem_dim, global_point, element_region_id)
            else if (trim(geometry_name) == 'placenta') then
                translated_point = translate_placenta_to_placentone_point(problem_dim, global_point, element_region_id)
            else if (trim(geometry_name) == 'placentone-3d') then
                translated_point = translate_placentone_3d_to_placentone_point(problem_dim, global_point, element_region_id)
            else if (geometry_name(1:6) == 'square') then
                translated_point = 0.0_db
            else
                print *, "Error in calculate_velocity_reaction_coefficient. Missed case."
                print *, "geometry_name = ", geometry_name
                error stop
            end if
        else
            translated_point = 0.0_db
        end if

        if (geometry_name(1:6) == 'square') then
            calculate_transport_reaction_coefficient = transport_reaction_coefficient
        else
            ! IVS.
            if (300 <= element_region_id .and. element_region_id <= 399) then
                calculate_transport_reaction_coefficient = transport_reaction_coefficient* &
                    1.0_db
            ! Arteries.
            else if (element_region_id == 412 .or. element_region_id == 422 .or. element_region_id == 432 .or. &
                    element_region_id == 442 .or. element_region_id == 452 .or. element_region_id == 462 .or. &
                    element_region_id == 472) then
                calculate_transport_reaction_coefficient = &
                    0.0_db
            ! Veins.
            else if (400 <= element_region_id .and. element_region_id <= 499) then
                calculate_transport_reaction_coefficient = transport_reaction_coefficient* &
                    calculate_placentone_pipe_transition(translated_point, problem_dim, element_region_id, steepness)
            ! Cavities.
            else if (500 <= element_region_id .and. element_region_id <= 509) then
                calculate_transport_reaction_coefficient = &
                    0.0_db
            ! Cavity transitions.
            else if (510 <= element_region_id .and. element_region_id <= 527) then
                placentone_no = mod(element_region_id, 10)
                calculate_transport_reaction_coefficient = transport_reaction_coefficient* &
                    calculate_placentone_cavity_transition(translated_point, problem_dim, element_region_id, steepness, &
                        placentone_no)
            else
                print *, "Error in calculate_transport_reaction_coefficient. Missed case."
                print *, "element_region_id = ", element_region_id
                error stop
            end if
        end if
    end function

    function calculate_transport_time_coefficient(global_point, problem_dim, element_region_id)
        use param

        real(db)                                     :: calculate_transport_time_coefficient
        integer, intent(in)                          :: problem_dim
        real(db), dimension(problem_dim), intent(in) :: global_point
        integer, intent(in)                          :: element_region_id

        calculate_transport_time_coefficient = transport_time_coefficient
    end function

    function calculate_transport_forcing_coefficient(global_point, problem_dim, element_region_id)
        use param

        real(db)                                     :: calculate_transport_forcing_coefficient
        integer, intent(in)                          :: problem_dim
        real(db), dimension(problem_dim), intent(in) :: global_point
        integer, intent(in)                          :: element_region_id

        calculate_transport_forcing_coefficient = transport_forcing_coefficient
    end function
end module