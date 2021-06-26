baremodule Godbolt

function post end
function post_llvm end
function post_native end

macro post_llvm end
macro post_native end

module Internal

import ..Godbolt: @post_llvm, @post_native
using ..Godbolt: Godbolt

import HTTP
import JSON
using Base64: base64encode
using InteractiveUtils:
    InteractiveUtils,
    code_llvm,
    code_native,
    gen_call_with_extracted_types_and_kwargs,
    print_llvm,
    print_native

include("post.jl")
include("interactive.jl")

# Use README as the docstring of the module:
@doc let path = joinpath(dirname(@__DIR__), "README.md")
    include_dependency(path)
    read(path, String)
end Godbolt

end  # module Internal

end  # baremodule Godbolt
