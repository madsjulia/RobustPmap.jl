module RobustPmap

function checkexceptions(x, t)
	for i = 1:length(x)
		if isa(x[i], RemoteException)
			throw(x[i])
		elseif !isa(x[i], t)#typeof(x[i]) != t
			throw(TypeError(:rpmap, "", t, x[i]))
		end
	end
	return nothing
end

function rpmap(f, args...; t::Type=Any)
	x = pmap(f, args...)
	checkexceptions(x, t)
	return convert(Array{t, 1}, x)
end

end
