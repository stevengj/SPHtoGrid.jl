"""
    sphMapping( Pos, HSML, Bin_Quant;
                param::mappingParameters,
                kernel::AbstractSPHKernel,
                show_progress::Bool=true,
                parallel::Bool=false,
                reduce_image::Bool=true,
                filter_particles::Bool=true,
                dimensions::Int=2)

Maps the data in `Bin_Quant` to a grid. Parameters of mapping are supplied in
`param` and the kernel to be used in `kernel`.

# Arguments
- `Pos`: Matrix (3xNpart) with particle positions.
- `HSML`: Array with particle hsml.
- `Bin_Quant`: Array with particle quantity to be mapped.
- `kernel::AbstractSPHKernel`: Kernel object to be used.
- `show_progress::Bool=true`: Show progress bar.
- `parallel::Bool=true`: Run on multiple processors.
- `reduce_image::Bool=true`: If weights need to be applied or not. Set to `false` for [`part_weight_one`](@ref) and [`part_weight_physical`](@ref).
- `filter_particles::Bool=true`: Find the particles that are actually contained in the image.
- `dimensions::Int=2`: Number of mapping dimensions (2 = to grid, 3 = to cube).
"""
function sphMapping(Pos::Matrix{<:Real}, HSML::Vector{<:Real}, Bin_Quant::Vector{<:Real};
                    param::mappingParameters,
                    kernel::AbstractSPHKernel,
                    show_progress::Bool = true,
                    parallel::Bool = false,
                    reduce_image::Bool = true,
                    filter_particles::Bool = true,
                    dimensions::Int = 2)


    # store number of input particles
    N_in = size(Bin_Quant, 1)

    # First check if all particles are centered around 0 and shift them if they are not
    if show_progress
        @info "Centering on [0.0, 0.0, 0.0]"
        t1 = time_ns()
    end
    Pos, par = check_center_and_move_particles(Pos, param)

    if show_progress
        t2 = time_ns()
        @info "  elapsed: $(output_time(t1,t2)) s"
    end

    # filter particles if they are contained in the image
    if show_progress
        @info "Filtering particles..."
        t1 = time_ns()
    end

    if filter_particles
        p_in_image = filter_particles_in_image(Pos, HSML, param)
    else
        p_in_image = trues(N_in)
    end

    if show_progress
        t2 = time_ns()
        @info "  elapsed: $(output_time(t1,t2)) s"
    end

    # if this is not a float it has units, which need to be stripped
    if !(typeof(Bin_Quant[1]) <: AbstractFloat)

        if show_progress
            @info "Stripping units..."
            t1 = time_ns()
        end

        # allocate reduced arrays
        x = ustrip.(Pos[:, p_in_image])
        hsml = ustrip.(HSML[p_in_image])
        bin_q = ustrip.(Bin_Quant[p_in_image])

    else
        if show_progress
            @info "Assigning arrays..."
            t1 = time_ns()
        end

        # allocate reduced arrays
        x = Pos[:, p_in_image]
        hsml = HSML[p_in_image]
        bin_q = Bin_Quant[p_in_image]
    end

    if show_progress
        t2 = time_ns()
        @info "  elapsed: $(output_time(t1,t2)) s"
    end

    N_map = length(hsml)

    @info "Particles in image: $N_map / $N_in"


    if show_progress
        @info "Mapping..."
        t1 = time_ns()
    end

    if (dimensions == 2)

        if !parallel
        
            image = splash_mapping_2D(x, hsml, bin_q;
                param = par, kernel = kernel,
                show_progress = show_progress)
        
            if show_progress
                t2 = time_ns()
                @info "  elapsed: $(output_time(t1,t2)) s"
            end
        
            return reduce_image_2D(image,
                param.Npixels[1], param.Npixels[2])
        else
            @info "Running on $(nworkers()) cores."
        
            # Number of particles
            N = length(hsml)
        
            # allocate an array of Future objects
            futures = Array{Future}(undef, nworkers())
        
            # 'Domain decomposition':
            # calculate array slices for each worker
            batch = domain_decomposition(N, nworkers())
        
            # start remote processes
            for (i, id) in enumerate(workers())
                futures[i] = @spawnat id splash_mapping_2D(x[:, batch[i]], hsml[batch[i]],
                    bin_q[batch[i]];
                    param = par, kernel = kernel,
                    show_progress = false)
            end
        
            image = sum(fetch.(futures))
        
            if show_progress
                t2 = time_ns()
                @info "  elapsed: $(output_time(t1,t2)) s"
            end
        
            return reduce_image_2D(image,
                param.Npixels[1], param.Npixels[2])
        end

    elseif (dimensions == 3)
        if !parallel
            image = splash_mapping_3D(x, hsml, bin_q;
                param = par, kernel = kernel,
                show_progress = show_progress)
        
            if show_progress
                t2 = time_ns()
                @info "  elapsed: $(output_time(t1,t2)) s"
            end
        
            reduce_image_3D(image,
                param.Npixels[1], param.Npixels[2], param.Npixels[3])
        else
            @info "Running on $(nworkers()) cores."
        
            N = length(hsml)
            futures = Array{Future}(undef, nworkers())
        
            # 'Domain decomposition':
            # calculate array slices for each worker
            batch = domain_decomposition(N, nworkers())
        
            # start remote processes
            for (i, id) in enumerate(workers())
                futures[i] = @spawnat id splash_mapping_3D(x[:, batch[i]], hsml[batch[i]],
                    bin_q[batch[i]];
                    param = par, kernel = kernel,
                    show_progress = false)
            end
        
            # get and reduce results
            image = sum(fetch.(futures))
        
            if show_progress
                t2 = time_ns()
                @info "  elapsed: $(output_time(t1,t2)) s"
            end
        
            return reduce_image_3D(image,
                param.Npixels[1], param.Npixels[2], param.Npixels[3])
        end
    end



end