#=
Use the data channel for the settings data...
=#
struct SettingsData
    terminate::Bool
    pause::Bool
    delete_particles::Bool
    delete_walls::Bool
    new_wall::NTuple{2, Point2{Float64}}
    accomodation_coefficient::Float64
    inflow_density::Float64
    inflow_velocity::Float64
    plot_type::Symbol # :particles, :density, :velocity, :temperature
    SettingsData() = new(
        false, true, false, false,
        (Point2f(NaN,NaN), Point2f(NaN,NaN)),
        0, 0, 0,
        :particles
    )
end

function send!(data, c::DataChannel{SettingsData})
    _send_data!(fill_data!::Function, c)
end

mutable struct Settings
    data::SettingsData
    channel::DataChannel{T}
    Settings() = new(SettingsData(), DataChannel(SettingsData))
end

data(s::Settings) = s.data

function receive!(s::Settings)
    s.data = copy(_receive_data!(s.channel))
end

request!(s::Settings) = _request_data!(s.channel)


