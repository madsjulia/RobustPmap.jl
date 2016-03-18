import RobustPmap
using Base.Test

if nworkers() < 2
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
testtypecheck()
testworks()
testparallel()
rmprocs(workers())