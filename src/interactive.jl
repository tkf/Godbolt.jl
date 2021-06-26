function Godbolt.post_llvm(args...; kwargs...)
    code = sprint() do io
        @nospecialize
        code_llvm(io, args...; dump_module = true, kwargs...)
    end
    return Godbolt.post(code; language = "llvm")
end

function Godbolt.post_native(args...; kwargs...)
    code = sprint() do io
        @nospecialize
        code_native(io, args...; kwargs...)
    end
    return Godbolt.post(code; language = "analysis")
end

macro post_llvm(args...)
    gen_call_with_extracted_types_and_kwargs(__module__, Godbolt.post_llvm, args)
end

macro post_native(args...)
    gen_call_with_extracted_types_and_kwargs(__module__, Godbolt.post_native, args)
end
