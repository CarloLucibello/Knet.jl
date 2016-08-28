include("cuda1.jl")
using CUDArt
libknet8handle = Libdl.dlopen(Libdl.find_library(["libknet8"],[Pkg.dir("Knet/cuda")]))

SIZE = 100000
ITER = 100000
x32 = KnetArray(rand(Float32,SIZE))
y32 = similar(x32)
x64 = KnetArray(rand(Float64,SIZE))
y64 = similar(x64)

function cuda1test(fname, jname=fname, o...)
    println(fname)
    fcpu = eval(parse(jname))
    f32 = Libdl.dlsym(libknet8handle, fname*"_32")
    @time cuda1rep(f32,x32,y32)
    isapprox(to_host(y32),fcpu(to_host(x32))) || warn("$fname 32")
    f64 = Libdl.dlsym(libknet8handle, fname*"_64")
    @time cuda1rep(f64,x64,y64)
    isapprox(to_host(y64),fcpu(to_host(x64))) || warn("$fname 64")
end

function cuda1rep{T}(f,x::KnetArray{T},y::KnetArray{T})
    n = Cint(length(y))
    for i=1:ITER
        ccall(f,Void,(Cint,Ptr{T},Ptr{T}),n,x,y)
    end
    device_synchronize()
    CUDArt.rt.checkerror(CUDArt.rt.cudaGetLastError())
end

for f in cuda1
    isa(f,Tuple) || (f=(f,))
    cuda1test(f...)
end