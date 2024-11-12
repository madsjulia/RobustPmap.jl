__precompile__()

"""
MADS: Model Analysis & Decision Support in Julia (Mads.jl v1.0) 2016
"""
module RobustPmap

import Distributed

import JLD2
import FileIO

"Check for exceptions"
function checkexceptions(x::Any, t::Type=Any, args...)
	for i in eachindex(x)
		if isa(x[i], Exception)
			@error("Execution failed for one of the runs (run #$(i)) with exception error $(typeof(x[i]))!")
			@error("Failing input parameter set: $(args[1][i])")
			throw(TypeError(:RobustPmap, t, x[i]))
		elseif !isa(x[i], t)
			@error("Execution failed for one of the runs (run #$(i))")
			@error("Failing input parameter set: $(args[1][i])")
			throw(TypeError(:RobustPmap, t, x[i]))
		end
	end
	return nothing
end

"Robust pmap call"
function rpmap(f::Function, args...; t::Type=Any)
	x = Distributed.pmap(f, args...; on_error=x->x)
	checkexceptions(x, t, args...)
	return convert(Vector{t}, x)
end

"Robust pmap call with checkpoints"
function crpmap(f::Function, checkpointfrequency::Int, filerootname::AbstractString, args...; t::Type=Any)
	fullresult = t[]
	hashargs = hash(args)
	if checkpointfrequency <= 0
		checkpointfrequency = length(args[1])
	end
	for i = 1:ceil(Int, length(args[1]) / checkpointfrequency)
		r = (1 + (i - 1) * checkpointfrequency):min(length(args[1]), (i * checkpointfrequency))
		filename = string(filerootname, "_", hashargs, "_", i, ".jld2")
		theseargs = map(x->x[r], args)
		if isfile(filename)
			partialresult = FileIO.load(filename, "partialresult")
		else
			partialresult = rpmap(f, map(x->x[r], args)...; t=t)
			FileIO.save(filename, "partialresult", partialresult)
		end
		append!(fullresult, partialresult)
	end
	return fullresult
end

end
