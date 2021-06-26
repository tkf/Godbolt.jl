"""
    Godbolt.post(code; [language], [compiler], [options]) -> post

Post `code` to godbolt.org. The URL is available through `post.url` property.
"""
function Godbolt.post(
    code::AbstractString;
    language::AbstractString = maybe_llvm(code) ? "llvm" : "assembly",
    compiler::Union{AbstractString,Nothing} = default_compiler(language),
    options::AbstractString = "",
)
    s = SimpleSession(; code, language, compiler, options)
    url = _post(s)
    return Post(url, s)
end

maybe_llvm(code::AbstractString) = match(r"define .* @.*\(\) .*{", code)
default_compiler(language) =
    if language == "llvm"
        major = Int(Base.libllvm_version.major)
        minor = Int(Base.libllvm_version.minor)
        patch = Int(Base.libllvm_version.patch)
        "llc$major$minor$patch"
    elseif language == "analysis"
        # "llvm-mcatrunk"
        "osacatrunk"
    else
        nothing
    end

Base.@kwdef struct SimpleSession
    code::String

    # `id` of https://godbolt.org/api/languages
    language::String

    # `id` of https://godbolt.org/api/compilers
    compiler::Union{String,Nothing}

    options::String = ""
end
# https://github.com/compiler-explorer/compiler-explorer/blob/master/docs/API.md


Base.@kwdef struct Post
    url::String
    session::SimpleSession
end

function clientstate(s::SimpleSession)
    if s.compiler === nothing
        compilers = []
    else
        compilers = [Dict("id" => s.compiler, "options" => s.options)]
    end
    code = s.code
    if s.language == "analysis"
        # Strip out comments:
        code = sprint() do io
            for ln in eachline(IOBuffer(code); keep = true)
                startswith(ln, ";") && continue
                print(io, ln)
            end
        end
    end
    sessions =
        [Dict("language" => s.language, "source" => code, "compilers" => compilers)]
    return Dict("sessions" => sessions)
end

function _post(s::SimpleSession)
    url = godbolt_base64url(s)
    # Use URL shortener for URL longer than 2000 characters
    # https://stackoverflow.com/a/417184
    if length(url) > 2000
        url = post_shorturl(s)
    end
    return url
end

function godbolt_base64url(s::SimpleSession)
    path = base64encode(JSON.print, clientstate(s))
    return "https://godbolt.org/clientstate/$path"
end

function post_shorturl(s::SimpleSession)
    response = HTTP.post(
        "https://godbolt.org/shortener",
        ["Content-Type" => "application/json", "Accept" => "application/json"],
        JSON.json(clientstate(s)),
    )
    msg = JSON.parse(String(response.body))
    return msg["url"]
end

function print_code(io::IO, code, language)
    if get(io, :color, false)
        if language == "llvm"
            print_llvm(io, code)
            return
        elseif language == "assembly"
            print_native(io, code)
            return
        end
    end
    print(io, code)
end

function Base.show(io::IO, ::MIME"text/plain", p::Post)
    println(io, p.session.language, " code posted to godbolt.org")
    print_code(io, p.session.code, p.session.language)
    println(io)
    println(io)
    print(io, "URL: ")
    printstyled(io, p.url; color = :blue)
end
