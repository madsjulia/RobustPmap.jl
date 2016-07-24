import RobustPmap
using Base.Test

procschage = false
if nworkers() < 2
	procschage = true
	addprocs(2)
end
@everywhere f1(x) = x > 0 ? 1 : 1.
function testtypecheck()
	@test_throws TypeError RobustPmap.rpmap(f1, [-1, 0, 1]; t=Int)
end
function testworks()
	@test RobustPmap.rpmap(f1, [-1, 0, 1]) == Any[1., 1., 1]
end
function testparallel()
	@test length(unique(RobustPmap.rpmap(i->myid(), 1:2))) != 1
end
function testcheckpoint()
	result = RobustPmap.crpmap(x->x, 2, joinpath(pwd(), "test"), [-1, 0, 1]; t=Int)
	result2 = RobustPmap.crpmap(x->pi, 2, joinpath(pwd(), "test"), [-1, 0, 1]; t=Int)#test it with a different function to make sure it loads from the checkpoints
	rm(joinpath(pwd(), string("test", "_", hash(([-1, 0, 1],)), "_1.jld")))
	rm(joinpath(pwd(), string("test", "_", hash(([-1, 0, 1],)), "_2.jld")))
	@test result == RobustPmap.rpmap(x->x, [-1, 0, 1]; t=Int)
	@test result == result2
	x = rand(100)
	y = rand(100)
	result = RobustPmap.crpmap((x, y)->x + y, 10, joinpath(pwd(), "test"), x, y; t=Float64)
	result2 = RobustPmap.crpmap((x, y)->pi, 10, joinpath(pwd(), "test"), x, y; t=Float64)#test it with a different function to make sure it loads from the checkpoints
	for i = 1:10
		rm(joinpath(pwd(), string("test", "_", hash((x, y)), "_$i.jld")))
	end
	@test result == RobustPmap.rpmap((x, y)->x + y, x, y; t=Float64)
	@test result == result2
end
testtypecheck()
testworks()
testparallel()
testcheckpoint()
function onlyonproc1(x)
	return x
end
@test_throws RemoteException RobustPmap.rpmap(onlyonproc1, 1:10)
if procschage
	rmprocs(workers())
end
