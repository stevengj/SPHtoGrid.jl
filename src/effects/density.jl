"""
    density_2D( rho::Real, pixelSideLength::Real, 
                Mass::Real=1.989e43, Length::Real=3.085678e21)

Computes the 2D density.

# Returns
2D surface density in untis of [g/cm^2].
"""
function density_2D(rho::Real, pixelSideLength::Real, 
                    Mass::Real=1.989e43, Length::Real=3.085678e21)
    return rho * ( (Mass / Length^2 ) * pixelSideLength )
end
