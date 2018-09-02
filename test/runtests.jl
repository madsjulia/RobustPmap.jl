procschage = false
if nworkers() < 2
	procschage = true
	addprocs(2)
	reload("RobustPmap")
	import Base.Test
end

if !isdefined(Symbol("@stderrcapture"))
	@everywhere macro stderrcapture(block)
		quote
			if ccall(:jl_generating_output, Cint, ()) == 0
				errororiginal = STDERR;
				(errR, errW) = redirect_stderr();
				errorreader = @async readstring(errR);
				evalvalue = $(esc(block))
				redirect_stderr(errororiginal);
				close(errW);
				close(errR);
				return evalvalue
			end
		end
	end
end

@stderrcapture @everywhere f1(x) = x > 0 ? 1 : 1.
@stderrcapture function testtypecheck()
	@Base.Test.test_throws TypeError RobustPmap.rpmap(f1, [-1, 0, 1]; t=Int)
end
@stderrcapture function testworks()
	@Base.Test.test RobustPmap.rpmap(f1, [-1, 0, 1]) == Any[1., 1., 1]
end
@stderrcapture function testparallel()
	@Base.Test.test length(unique(RobustPmap.rpmap(i->myid(), 1:2))) != 1
end
@stderrcapture function testcheckpoint()
	result = RobustPmap.crpmap(x->x, 2, joinpath(pwd(), "test"), [-1, 0, 1]; t=Int)
	result2 = RobustPmap.crpmap(x->pi, 2, joinpath(pwd(), "test"), [-1, 0, 1]; t=Int)#test it with a different function to make sure it loads from the checkpoints
	rm(joinpath(pwd(), string("test", "_", hash(([-1, 0, 1],)), "_1.jld")))
	rm(joinpath(pwd(), string("test", "_", hash(([-1, 0, 1],)), "_2.jld")))
	@Base.Test.test result == RobustPmap.rpmap(x->x, [-1, 0, 1]; t=Int)
	@Base.Test.test result == result2
	x = rand(100)
	y = rand(100)
	result = RobustPmap.crpmap((x, y)->x + y, 10, joinpath(pwd(), "test"), x, y; t=Float64)
	result2 = RobustPmap.crpmap((x, y)->pi, 10, joinpath(pwd(), "test"), x, y; t=Float64)#test it with a different function to make sure it loads from the checkpoints
	for i = 1:10
		rm(joinpath(pwd(), string("test", "_", hash((x, y)), "_$i.jld")))
	end
	@Base.Test.test result == RobustPmap.rpmap((x, y)->x + y, x, y; t=Float64)
	@Base.Test.test result == result2
end
@stderrcapture function onlyonproc1(x)
	return x
end

@Base.Test.testset "RobustPmap" begin
	testtypecheck()
	testworks()
	testparallel()
	testcheckpoint()
	@Base.Test.test_throws RemoteException RobustPmap.rpmap(onlyonproc1, 1:10)
end

if procschage
	rmprocs(workers())
end

:passed
